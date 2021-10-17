# VPS setup

Configuration for my VPS. Assumes Debian 11.


## Initial configuration

At first, some minimal configuration is needed.


### Basic setup

* Update the system.
  ```
  # apt update && apt upgrade
  ```
* Change the root password.
  ```
  # passwd root
  ```
* Create a user.
  ```
  # apt install sudo
  # useradd -m -G sudo -s /bin/bash <username>
  # passwd <username>
  # chmod 700 /home/<username>
  ```


### Transfer the SSH key

* Log out and transfer the key.
  ```
  $ ssh-copy-id -i ~/.ssh/<public-key> <username>@<host>
  ```
* Log back in as the newly created user and change permissions.
  ```
  $ sudo chmod 600 /home/<username>/.ssh/authorized_keys
  ```


### Configure SSH

* The configuration involves changing the default SSH port from 22 to deter
  dumb bots.
* The settings are based on the [Mozilla OpenSSH
  guidelines](https://infosec.mozilla.org/guidelines/openssh). Only non-default
  settings are included.
* Copy [sshd_config](etc/ssh/sshd_config) to `/etc/ssh/sshd_config`.
* Deactivate short Diffie-Hellman moduli.
  ```
  $ awk '$5 >= 3071' /etc/ssh/moduli | sudo tee /etc/ssh/moduli.tmp > /dev/null && sudo mv /etc/ssh/moduli.tmp /etc/ssh/moduli
  $ sudo systemctl restart sshd.service
  ```
* Relog.


### Setup a firewall

```
$ sudo apt install nftables
$ sudo systemctl enable --now nftables.service
```
* Copy [nftables.conf](etc/nftables.conf) to `/etc/nftables.conf`.
* Set the `<WAN-INTERFACE>` variable for the Internet-facing interface name.
* Load the configuration.
  ```
  $ sudo nft -f /etc/nftables.conf
  ```


### Enable automatic updates

```
$ sudo apt install unattended-upgrades
```
* Add the following to `/etc/apt/apt.conf.d/20auto-upgrades`:
  ```
  APT::Periodic::Update-Package-Lists "1";
  APT::Periodic::Unattended-Upgrade "1";
  ```

## Security hardening

The goal of this section is twofold. First, WireGuard is set up as a secure way
to access the server. This includes hiding the SSH server behind it. Second,
the support for tunneling all traffic from a client through the server. This
involves making sure that there are no DNS leaks. As such, Unbound is set up as
a local DNS resolver and configured to be used by all WireGuard peers connected
to the server.

### WireGuard server setup

* Install WireGuard.
* Generate the server key.
  ```
  # wg genkey | (umask 0077 && tee /etc/wireguard/private.key) | wg pubkey > /etc/wireguard/public.key
  ```
* Create the server configuration in `/etc/wireguard/wg0.conf`.
  ```
  [Interface]
  Address = 10.200.200.1/24
  PrivateKey = <server-private-key>
  ListenPort = 51820
  ```
* Set NetworkManager to ignore the WireGuard interface. Add the following
to `/etc/NetworkManager/conf.d/unmanaged.conf`:
  ```
  [keyfile]
  unmanaged-devices=type:wireguard
  ```
* Enable IP forwarding on the server. Add the following to
`/etc/sysctl.conf` and reboot:
  ```
  net.ipv4.ip_forward=1
  net.ipv6.conf.all.forwarding=1
  ```
* Enable the WireGuard interface.
  ```
  # chown -R root:root /etc/wireguard/
  # chmod 600 /etc/wireguard/wg0.conf
  # wg-quick up wg0
  # systemctl enable --now wg-quick@wg0.service
  ```


### SSH configuration

* Add the following to `/etc/ssh/sshd_config`:
  ```
  ListenAddress 10.200.200.1
  AddressFamily inet
  ```
* Make sure that the `sshd` service is only started after the WireGuard
  interface has been set up. Run `sudo systemctl edit sshd.service` and add the
  following:
  ```
  [Unit]
  After=network.target wg-quick@wg0.service
  Requires=sys-devices-virtual-net-wg0.device
  ```
* Finally, restart the `sshd` service.
  ```
  $ sudo systemctl restart sshd.service
  ```


### Unbound setup

* Install unbound.
* Copy [unbound.conf](etc/unbound/unbound.conf) to `/etc/unbound/unbound.conf`.
* For security, unbound is chrooted into `/etc/unbound`. However, it needs
  access to entropy and to the system log, so they must be bound inside the
  chroot. To make the binding persistent, the information needs to be added to
  `/etc/fstab`.
  ```
  $ sudo mkdir -p /etc/unbound/dev
  $ sudo touch /etc/unbound/dev/random
  $ sudo touch /etc/unbound/dev/log
  ```
  Add the following lines to `/etc/fstab`.
  ```
  /dev/random /etc/unbound/dev/random none bind 0 0
  /dev/log /etc/unbound/dev/log none bind 0 0
  ```
  Furthermore, to periodically probe the root anchor, the directory
  `/etc/unbound` as well as the file `/etc/unbound/trusted-key.key` must be
  writable by the `unbound` user.
* Next, NetworkManager needs to be configured not to overwrite the DNS server
  address with the DHCP-supplied one. Create a
  `/etc/NetworkManager/conf.d/dns.conf` file with the following contents.
  ```
  [main]
      dns=none
  ```
  Then, restart NetworkManager and enable and start unbound.
  ```
  $ sudo systemctl restart NetworkManager.service
  $ sudo systemctl enable --now unbound.service
  ```


### WireGuard client setup

* Install WireGuard.
* Generate the client key.
  ```
  # wg genkey | (umask 0077 && tee /etc/wireguard/private.key) | wg pubkey > /etc/wireguard/public.key
  ```
* Create the client configuration in `/etc/wireguard/wg0.conf`.
  ```
  [Interface]
  Address = <client-address-within-10.200.200.0/24-e.g.-10.200.200.2/32>
  PrivateKey = <client-private-key>
  DNS = 10.200.200.1
  MTU = 1420

  [Peer]
  PublicKey = <server-public-key>
  Endpoint = <server-hostname-or-ip-address>:51820
  AllowedIPs = 0.0.0.0/0, ::/0
  ```
* Insert the client to the server configuration.
  ```
  [Peer]
  PublicKey = <client-public-key>
  AllowedIPs = <client-address-within-10.200.200.0/24-e.g.-10.200.200.2/32>
  ```


## Services

Finally, various services running on the server can be configured.


### nginx and certbot

* This assumes that a domain has been registered for the server. If not, it
  is possible to setup a self-signed certificate to encrypt the connection,
  though obviously without any verification.
* In the `certbot` command below, you will be asked to enter your domain
  name. From now on, this will be referred to as `YOUR-DOMAIN`. We generate
  a certificate but do not modify the nginx config, because it would
  overwrite our settings.
  ```
  $ sudo apt update
  $ sudo apt install snapd
  $ sudo reboot
  $ sudo snap install core && sudo snap refresh core
  $ sudo snap install --classic certbot
  $ sudo ln -s /snap/bin/certbot /usr/bin/certbot
  $ sudo certbot certonly --key-type ecdsa --nginx
  ```
* Copy [nginx](etc/nginx) to `/etc/nginx`. **Do not forget to replace
  `<YOUR-DOMAIN>` with your domain and `<DNS-SERVER-1>` and `<DNS-SERVER-2>`
  with the DNS servers your server is using. Also rename
  [etc/nginx/sites-available/YOUR-DOMAIN.conf](nginx/sites-available/YOUR-DOMAIN.conf)
  based on your domain.**
* The configuration is based on the [Mozilla SSL Configuration
  Generator](https://ssl-config.mozilla.org/).
  ```
  $ sudo rm /etc/nginx/sites-enabled/default /etc/nginx/sites-available/default
  $ sudo ln -s /etc/nginx/sites-available/YOUR-DOMAIN.conf /etc/nginx/sites-enabled/
  $ sudo nginx -t  # Verify that there are no errors in the config.
  $ sudo systemctl enable --now nginx.service
  ```
* To verify that certbot auto-renewal is set, check either the crontab or the
  systemd timers. You can also use the following command.
  ```
  $ sudo certbot renew --dry-run
  ```
* Optionally, you can use the [Mozilla
  Observatory](https://observatory.mozilla.org/) to check your configuration.


### git

```
$ sudo apt install git
```
* Create an unprivileged git user.
```
$ sudo useradd -r -m -U -d /home/git -s /bin/bash git
$ sudo passwd git

# Allow the main user to access the git directory and to initialize repos.
$ sudo chmod 755 /home/git
```
* Set the limited `git-shell` as the git user's shell.
  * Make sure that `git-shell` is present in `/etc/shells`.
    ```
    $ cat /etc/shells
    ```
  * If not, add it.
    ```
    $ which git-shell | sudo tee -a /etc/shells
    ```
  * Change the git user's shell. From now on, the user's access is
    restricted to the pull/push functionality.
    ```
    $ sudo chsh git -s $(which git-shell)
    ```
* Transfer the SSH key.
  ```
  $ ssh-copy-id -i ~/.ssh/<public-key-git> git@<host>
  ```
* Relog and change permissions.
  ```
  $ sudo chmod 600 /home/git/.ssh/authorized_keys
  ```
* Recommended SSH configuration on the local computer (i.e., not the server).
  * Put this into `~/.ssh/config`.
    ```
    Host vps-git
        User git
        Hostname <YOUR-DOMAIN>
        Port 10022
        IdentitiesOnly yes
        IdentityFile ~/.ssh/<PRIVATE-KEY-GIT>
    ```
  * This configuration allows simplifying git queries to the server. It is no
    longer necessary to specify the different SSH port and it is possible to
    use a unique SSH key. Furthermore, `IdentitiesOnly yes` ensures that SSH
    will not try all your keys but immediately use the specified one.
* The following is a template to initialize a new git repository on the server.
  This must be repeated for each new repository.
  * On the server side, logged as the main user (the git user does not have a
    proper shell, so login is impossible anyway).
    ```
    $ sudo mkdir /home/git/<REPO-NAME>.git
    $ cd /home/git/<REPO-NAME>.git
    $ sudo git init --bare
    $ sudo chown -R git:git /home/git/<REPO-NAME>.git
    ```
  * On the client side, clone the repository.
    ```
    $ git clone vps-git:<REPO-NAME>.git
    ```
  * Alternatively, you can initialize an empty Git repository and point it to
    the server.
    ```
    $ cd <REPO-DIRECTORY>
    $ git init
    $ touch README.md
    $ git add -A
    $ git commit -m "Initial commit"
    $ git remote add origin vps-git:<REPO-NAME>.git
    $ git push origin master
    ```
* To mirror an existing repository to the VPS, do the following.
  * Create the bare repository on the server, as described above.
  * On the client side, do the following in the repository.
    ```
    $ git remote set-url origin --add vps-git:<REPO-NAME>.git
    $ git push
    ```
  * On the server side: `cd` to the repository and `git log` to check it. If
    your master branch is not called `master` and you get `fatal: your
    current branch 'master' does not have any commits yet`, do the
    following.
    ```
    $ sudo git symbolic-ref HEAD refs/heads/<MASTER-BRANCH-NAME>
    ```


### rsync

```
$ sudo apt install rsync
```
* Create an unprivileged rsync user.
  ```
  $ sudo useradd -r -m -U -d /home/storage -s /bin/bash storage
  $ sudo passwd storage

  # Allow the main user to access the rsync directory and to initialize dirs.
  $ sudo chmod 755 /home/storage
  ```
* Transfer the SSH key.
  ```
  $ ssh-copy-id -i ~/.ssh/<public-key-storage> storage@<host>
  ```
* Relog and change permissions.
  ```
  $ sudo chmod 600 /home/storage/.ssh/authorized_keys
  ```
* Configure the restricted rsync (`rrsync`) script that came with the `rsync`
  installation.
  ```
  $ sudo ln -fs /usr/share/doc/rsync/scripts/rrsync /usr/bin/rrsync
  $ sudo chmod +x /usr/share/doc/rsync/scripts/rrsync
  ```
* Restrict the rsync user to only be able to use the `rrsync` script inside
  their home directory with a limited SSH connection.
  * Edit the `~/storage/.ssh/authorized_keys` file to look like
    ```
    command="/usr/bin/rrsync /home/storage/",restrict <key>
    ```
    where `<key>` is the SSH key transferred earlier.
