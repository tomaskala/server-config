# VPS setup

Configuration for my VPS. Assumes Debian 11.


## Initial configuration

At first, some minimal configuration is needed.


### Basic setup

* Update the system.
  ```
  # apt update && apt full-upgrade
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


### Transfer the SSH key and the configuration

* Log out and transfer the key and the contents of this directory.
  ```
  $ ssh-copy-id -i ~/.ssh/<public-key> <username>@<host>
  $ scp -i ~/.ssh/<private-key> -r ./* <username>@<host>:<path>
  ```
* Log back in as the newly created user and change the ownership.
  ```
  # chown -R root:root <path-to-etc-from-this-repo>
  ```


### Configure SSH

* The configuration involves changing the default SSH port from 22 to deter
  dumb bots.
* The settings are based on the [Mozilla OpenSSH
  guidelines](https://infosec.mozilla.org/guidelines/openssh). Only non-default
  settings are included.
```
# mv ./etc/ssh/sshd_config /etc/ssh/sshd_config
```
* Deactivate short Diffie-Hellman moduli.
  ```
  # awk '$5 >= 3071' /etc/ssh/moduli > /etc/ssh/moduli.tmp && mv /etc/ssh/moduli.tmp /etc/ssh/moduli
  # systemctl restart sshd.service
  ```
* Relog.


### Setup a firewall

```
# apt install nftables
# systemctl enable --now nftables.service
# mv ./etc/nftables.conf /etc/nftables.conf
```
* Set the `<WAN-INTERFACE>` variable for the Internet-facing interface name.
* Load the configuration.
  ```
  # /usr/sbin/nft -f /etc/nftables.conf
  ```


### Enable automatic updates

```
# apt install unattended-upgrades
```
* Add the following to `/etc/apt/apt.conf.d/20auto-upgrades`:
  ```
  APT::Periodic::Update-Package-Lists "1";
  APT::Periodic::Unattended-Upgrade "1";
  ```

## Security hardening

The goal of this section is twofold.

First, WireGuard is set up as a secure way to access the server. This includes
hiding the SSH server behind it.

Second, the support for tunneling all client traffic through the server is
implemented. This involves making sure that there are no DNS leaks. As such,
Unbound is set up as a local DNS resolver and configured to be used by all
WireGuard peers connected to the server.

In addition, unbound is configured with blocklists to make the internet a less
shitty place.


### WireGuard setup


#### Server

```
# apt install wireguard-tools
```
* Generate the server key.
  ```
  # umask 0077
  # mkdir -p /etc/wireguard/{keys,psk}
  # wg genkey | tee /etc/wireguard/keys/wg0_private.key | wg pubkey > /etc/wireguard/keys/wg0_public.key
  ```
* Create the server configuration in `/etc/wireguard/wg0.conf`.
  ```
  [Interface]
  Address = 10.200.200.1/24
  PrivateKey = <server-private-key>
  ListenPort = 1194
  ```
* Enable IP forwarding on the server. Add the following to
  `/etc/sysctl.d/local.conf`:
  ```
  net.ipv4.ip_forward=1
  net.ipv6.conf.all.forwarding=1
  ```
* Enable the WireGuard interface.
  ```
  # chown -R root:root /etc/wireguard/
  # chmod 600 /etc/wireguard/wg0.conf
  # systemctl enable --now wg-quick@wg0.service
  ```


#### Client

* Install WireGuard.
* Generate the pre-shared key on the server (unique for each client):
  ```
  # wg genpsk > /etc/wireguard/psk/client_name.psk
  ```
* Generate the client key.
  ```
  # wg genkey | (umask 0077 && tee /etc/wireguard/private.key) | wg pubkey > /etc/wireguard/public.key
  ```
* Create the client configuration in `/etc/wireguard/wg0.conf`.
  ```
  [Interface]
  Address = <client-ip-address-inside-the-vpn>
  PrivateKey = <client-private-key>
  MTU = 1420

  [Peer]
  PublicKey = <server-public-key>
  PresharedKey = <preshared-key-for-the-client>
  Endpoint = <server-hostname-or-ip-address>:1194
  AllowedIPs = 10.200.200.1/32
  ```


#### Server

* Insert the client to the server configuration.
  ```
  [Peer]
  PublicKey = <client-public-key>
  PresharedKey = <preshared-key-for-the-client>
  AllowedIPs = <client-ip-address-inside-the-vpn>
  ```


### SSH configuration

* Add the following to `/etc/ssh/sshd_config`:
  ```
  ListenAddress 10.200.200.1
  AddressFamily inet
  ```
* Make sure that the `sshd` service is only started after the WireGuard
  interface has been set up.
  ```
  # systemctl edit --full sshd.service
  ```
  Change the `After` and `Requires` clauses inside `[Unit]` to contain the
  following:
  ```
  [Unit]
  ...
  After=network.target auditd.service wg-quick@wg0.service
  Requires=wg-quick@wg0.service
  ...
  ```
* Reload daemons and restart the sshd service:
  ```
  # systemctl daemon-reload
  # systemctl restart sshd.service
  ```
* From this point, the server is accessed on 10.200.200.1:10022 after having
  connected to the VPN.


### Unbound setup

```
# apt install unbound
# mv ./etc/unbound/unbound.conf /etc/unbound/unbound.conf
```
* For security, unbound is chrooted into `/etc/unbound`. However, it needs
  access to entropy and to the system log, so they must be bound inside the
  chroot. To make the binding persistent, the information needs to be added to
  `/etc/fstab`.
  ```
  # mkdir /etc/unbound/dev
  # touch /etc/unbound/dev/{log,random}
  ```
  Add the following lines to `/etc/fstab`.
  ```
  /dev/random /etc/unbound/dev/random none bind 0 0
  /dev/log /etc/unbound/dev/log none bind 0 0
  ```
* To periodically probe the root anchor, the directory `/etc/unbound` as well
  as the file `/etc/unbound/trusted-key.key` must be writable by the `unbound`
  user.
  ```
  # chown root:unbound /etc/unbound
  # chown root:unbound /etc/unbound/trusted-key.key
  # chmod g+w /etc/unbound /etc/unbound/trusted-key.key
  ```
* Restart unbound:
  ```
  # systemctl restart unbound.service
  ```

### Setup Unbound blocklists with periodic updates

```
# apt install curl
# mv ./bin/fetch-blocklists /usr/local/bin/fetch-blocklists
```
* Setup remote control in the unbound config and include the blocklist file.
  ```
  # unbound-control-setup -d /etc/unbound
  ```
  * Add the following to `/etc/unbound/unbound.conf`:
    ```
    remote-control:
      # Enable remote control with unbound-control(8).
      control-enable: yes

      # Listen for remote control on this interface only.
      control-interface: 127.0.0.1

      # Use this port for remote control.
      control-port: 8953

      # Unbound server key file.
      server-key-file: "/etc/unbound/unbound_server.key"

      # Unbound server certificate file.
      server-cert-file: "/etc/unbound/unbound_server.pem"

      # Unbound-control key file.
      control-key-file: "/etc/unbound/unbound_control.key"

      # Unbound-control certificate file.
      control-cert-file: "/etc/unbound/unbound_control.pem"

    # Include the blocklist file.
    include: "/etc/unbound/blocklist.conf"
    ```
* Add the following to the root crontab:
  ```
  0 5 * * 0 /usr/local/bin/fetch-blocklists > /etc/unbound/blocklist.conf && /usr/sbin/unbound-control reload
  ```
* Run the command manually to build the blocklist for the first time:
  ```
  # /usr/local/bin/fetch-blocklists > /etc/unbound/blocklist.conf && /usr/sbin/unbound-control reload
  ```


### WireGuard client configuration for full tunneling

* Add the following under `[Interface]` in `/etc/wireguard/wg0.conf`:
  ```
  DNS = 10.200.200.1
  ```
  and the following under the server `[Peer]`:
  ```
  AllowedIPs = 0.0.0.0/0, ::/0
  ```
* For the DNS clause to work, it is necessary to install `resolvconf`.
* If using `systemd-resolved`, the following must be added to the `[Interface]`
  section. Otherwise, the DNS setting is ignored and the default DNS servers
  leak through the VPN tunnel.
  ```
  PostUp = resolvectl dns %i 10.200.200.1; resolvectl domain %i "~."; resolvectl default-route %i true
  PreDown = resolvectl revert %i
  ```


### Reboot

* When all this has been configured, reboot the server.


## Services

Finally, various services running on the server can be configured.


### nginx and certbot

```
# apt install nginx
```
* This assumes that a domain has been registered for the server. If not, it
  is possible to setup a self-signed certificate to encrypt the connection,
  though obviously without any verification.
* In the `certbot` command below, you will be asked to enter your domain
  name. From now on, this will be referred to as `YOUR-DOMAIN`. We generate
  a certificate but do not modify the nginx config, because it would
  overwrite our settings.
  ```
  # apt update
  # apt install snapd
  # reboot
  # snap install core && snap refresh core
  # snap install --classic certbot
  # ln -s /snap/bin/certbot /usr/bin/certbot
  # certbot certonly --key-type ecdsa --nginx
  ```
```
# mv ./etc/nginx /etc/nginx
```
* **Do not forget to replace `<YOUR-DOMAIN>` with your domain and
  `<DNS-SERVER-1>` and `<DNS-SERVER-2>` with the DNS servers your server is
  using. Also rename
  [etc/nginx/sites-available/YOUR-DOMAIN.conf](nginx/sites-available/YOUR-DOMAIN.conf)
  based on your domain.**
* The configuration is based on the [Mozilla SSL Configuration
  Generator](https://ssl-config.mozilla.org/).
  ```
  # rm /etc/nginx/sites-enabled/default /etc/nginx/sites-available/default
  # ln -s /etc/nginx/sites-available/YOUR-DOMAIN.conf /etc/nginx/sites-enabled/
  # nginx -t  # Verify that there are no errors in the config.
  # systemctl enable --now nginx.service
  ```
* To verify that certbot auto-renewal is set, check either the crontab or the
  systemd timers. You can also use the following command.
  ```
  # certbot renew --dry-run
  ```
* Optionally, you can use the [Mozilla
  Observatory](https://observatory.mozilla.org/) to check your configuration.


### git

```
# apt install git
```
* Create an unprivileged git user.
```
# useradd -r -m -U -d /home/git -s /bin/bash git
# passwd git

# Allow the main user to access the git directory and to initialize repos.
# chmod 755 /home/git
```
* Set the limited `git-shell` as the git user's shell.
  * Make sure that `git-shell` is present in `/etc/shells`.
    ```
    $ cat /etc/shells
    ```
  * If not, add it.
    ```
    # which git-shell >> /etc/shells
    ```
  * Change the git user's shell. From now on, the user's access is
    restricted to the pull/push functionality.
    ```
    # chsh git -s $(which git-shell)
    ```
* Transfer the SSH key.
  ```
  $ ssh-copy-id -i ~/.ssh/<public-key-git> git@<host>
  ```
* Relog.
* Recommended SSH configuration on the local computer (i.e., not the server).
  ```
  Host vps-git
      User git
      Hostname 10.200.200.1
      Port 10022
      IdentitiesOnly yes
      IdentityFile ~/.ssh/<PRIVATE-KEY-GIT>
  ```
* The following is a template to initialize a new git repository on the server.
  This must be repeated for each new repository.
  * On the server side, logged as the main user (the git user does not have a
    proper shell, so login is impossible anyway).
    ```
    # mkdir /home/git/<REPO-NAME>.git
    # cd /home/git/<REPO-NAME>.git
    # git init --bare
    # chown -R git:git /home/git/<REPO-NAME>.git
    ```
  * On the client side, clone the repository.
    ```
    $ git clone vps-git:<REPO-NAME>.git
    ```
  * Alternatively, you can initialize an empty Git repository and point it to
    the server.
    ```
    $ cd <REPO-NAME>
    $ git init
    $ touch README.md
    $ git add -A
    $ git commit -m "Initial commit"
    $ git remote add origin vps-git:<REPO-NAME>.git
    $ git push -u origin master
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
    # git symbolic-ref HEAD refs/heads/<MASTER-BRANCH-NAME>
    ```


### rsync

```
# apt install rsync
```
* Create an unprivileged rsync user.
  ```
  # useradd -r -m -U -d /home/storage -s /bin/bash storage
  # passwd storage

  # Allow the main user to access the rsync directory and to initialize dirs.
  # chmod 755 /home/storage
  ```
* Transfer the SSH key.
  ```
  $ ssh-copy-id -i ~/.ssh/<public-key-storage> storage@<host>
  ```
* Relog.
* Configure the restricted rsync (`rrsync`) script that came with the `rsync`
  installation.
  ```
  # ln -fs /usr/share/doc/rsync/scripts/rrsync /usr/bin/rrsync
  # chmod +x /usr/share/doc/rsync/scripts/rrsync
  ```
* Restrict the rsync user to only be able to use the `rrsync` script inside
  their home directory with a limited SSH connection.
  * Edit the `~/storage/.ssh/authorized_keys` file to look like
    ```
    command="/usr/bin/rrsync /home/storage/",restrict <key>
    ```
    where `<key>` is the SSH key transferred earlier.
