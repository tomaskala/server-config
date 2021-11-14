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
  # useradd -m -G sudo -s /bin/bash tomas
  # passwd tomas
  # chmod 700 /home/tomas
  ```


### Transfer the SSH key and the configuration

* Log out and transfer the key and the contents of this directory.
  ```
  $ ssh-copy-id -i ~/.ssh/<public-key> tomas@<host>
  $ scp -i ~/.ssh/<private-key> -r ./* tomas@<host>:<path>
  ```
* Log back in as the newly created user and change the ownership.
  ```
  # chown -R root:root <this-repo>
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
  # umask 0022
  ```
* Create the server configuration in `/etc/wireguard/wg0.conf`.
  ```
  [Interface]
  Address = 10.200.200.1/24
  PrivateKey = <server-private-key>
  ListenPort = 1194
  ```
* Enable the WireGuard interface.
  ```
  # chmod 600 /etc/wireguard/wg0.conf
  # systemctl enable --now wg-quick@wg0.service
  ```


#### Client

* Install WireGuard.
* Generate the pre-shared key on the server (unique for each client):
  ```
  # umask 0077
  # wg genpsk > /etc/wireguard/psk/client_name.psk
  ```
* Generate the client key (on the client).
  ```
  # wg genkey | (umask 0077 && tee /etc/wireguard/private.key) | wg pubkey > /etc/wireguard/public.key
  ```
* Create the client configuration in `/etc/wireguard/wg0.conf` (on the client).
  ```
  [Interface]
  Address = <client-ip-address-inside-the-vpn>
  PrivateKey = <client-private-key>

  [Peer]
  PublicKey = <server-public-key>
  PresharedKey = <preshared-key-for-the-client>
  Endpoint = <server-hostname-or-ip-address>:1194
  AllowedIPs = 10.200.200.1/32
  ```
* Change the configuration permissions:
  ```
  # chmod 600 /etc/wireguard/wg0.conf
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
* From this point, the server is accessed on `10.200.200.1:10022` after having
  connected to the VPN.


### Unbound setup

```
# apt install unbound
# rm -r /etc/unbound/unbound.conf.d
# mkdir /etc/unbound/unbound.conf.d
# mv ./etc/unbound/* /etc/unbound/
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
# chmod 700 /usr/local/bin/fetch-blocklists
```
* Setup remote control in the unbound config and include the blocklist file.
  ```
  # /usr/sbin/unbound-control-setup -d /etc/unbound
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
    ```
* Add the following to the root crontab:
  ```
  0 5 * * 0 /usr/local/bin/fetch-blocklists > /etc/unbound/unbound.conf.d/blocklist.conf && /usr/sbin/unbound-control reload
  ```
* Run the command manually to build the blocklist for the first time:
  ```
  # /usr/local/bin/fetch-blocklists > /etc/unbound/unbound.conf.d/blocklist.conf && /usr/sbin/unbound-control reload
  ```


### WireGuard server configuration for full tunneling

* Enable IP forwarding on the server. Add the following to
  `/etc/sysctl.d/local.conf`:
  ```
  net.ipv4.ip_forward=1
  net.ipv6.conf.all.forwarding=1
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
# apt install nginx certbot python3-certbot-nginx
$ sudo certbot certonly --key-type ecdsa --nginx
# mv ./etc/nginx /etc/nginx
```
* The configuration is based on the [Mozilla SSL Configuration
  Generator](https://ssl-config.mozilla.org/).
  ```
  # rm /etc/nginx/sites-enabled/default /etc/nginx/sites-available/default
  # ln -sf /etc/nginx/sites-available/*.conf /etc/nginx/sites-enabled/
  # /usr/sbin/nginx -t  # Verify that there are no errors in the config.
  # systemctl enable --now nginx.service
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
# apt install git
```
* Make sure that `git-shell` is present in `/etc/shells`.
  ```
  # cat /etc/shells
  ```
* If not, add it.
  ```
  # which git-shell >> /etc/shells
  ```
* Create an unprivileged git user.
  ```
  # /usr/sbin/useradd -r -m -s "$(which git-shell)" git
  # passwd git

  # Allow the main user to access the git directory and to initialize repos.
  # chmod 755 /home/git
  ```
* The SSH keys need to be transferred manually at this point due to having
  disabled SSH password login and set `git-shell` as the `git` user's shell.
* Recommended SSH configuration on the client:
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
  * On the server side:
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
    $ git remote set-url --add origin vps-git:<REPO-NAME>.git
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
  # /usr/sbin/useradd -r -m -s /bin/bash storage
  # passwd storage

  # Allow the main user to access the rsync directory and to initialize dirs.
  # chmod 755 /home/storage
  ```
* The SSH keys need to be transferred manually at this point due to having
  disabled SSH password login and set `git-shell` as the `git` user's shell.
* Restrict the rsync user to only be able to use the `rrsync` script inside
  their home directory with a limited SSH connection.
  * Edit the `~/storage/.ssh/authorized_keys` file to look like
    ```
    command="/usr/bin/rrsync /home/storage/",restrict <key>
    ```
    where `<key>` is the SSH key transferred earlier.


### RSS

```
# apt install git gcc make
# mkdir -p /var/www/tomaskala.com/reader
# chown -R tomas:tomas /var/www/tomaskala.com/reader
$ cd
$ git clone git://git.codemadness.org/sfeed
$ cd sfeed
# make clean install
$ cp style.css /var/www/tomaskala.com/reader/style.css
$ mkdir -p ~/.config/sfeed ~/.local/share/sfeed
```

* Put the `sfeedrc` configuration file to `~/.config/sfeed/sfeedrc`.
* Add the following to the `tomas` crontab:
  ```
  0 */4 * * * /usr/local/bin/sfeed_update /home/tomas/.config/sfeed/sfeedrc && /usr/local/bin/sfeed_html /home/tomas/.local/share/sfeed/feeds/* > /var/www/tomaskala.com/reader/index.html
  ```
