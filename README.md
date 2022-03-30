# Server configuration

Configuration for my server. Assumes Debian 11.


## Ansible setup

```
$ python -m venv ./venv
$ source ./venv/bin/activate
$ python -m pip install -r requirements.txt
```


## First login

The first login is done under the `root` user. The main user is created and
python is installed, so that ansible can be run afterwards.
```
# apt install sudo python3
# useradd -m -s /bin/bash -G sudo <admin-username>
# passwd <admin-username>
```


## Copy the main user public key

```
$ ssh-copy-id -i <admin-user-public-key> <server-address>
```


## Server configuration

Before the VPN is set up and the SSH config alias can be used, the server
address must be overriden to its public address. This is done by specifying a
new inventory (note the trailing comma) and setting the `target` variable.


### Initialize and secure the server

At this point, the login is done using a password, as the SSH keys have not
been copied yet.
```
$ ansible-playbook -t init,security -i <server-address>, -e "target=<server-address> vpn_client_public_key=<vpn-client-public-key> vpn_client_preshared_key=<vpn-client-preshared-key> vpn_client=<vpn-client-address>" main.yml
```


### Setup services

The `git` user password variable only needs to be specified on the first run.
As the user is never accessed directly and his shell is set to `git-shell`,
this is more of a good practice, and we don't mind potentially leaking the
password in the local bash history. This is better than being prompted for the
password every time the playbook is run, or carrying an ansible vault around.
```
$ ansible-playbook -t services -e "git_password=<git-user-password>" main.yml
```


## Wireguard setup

### Client

* Install Wireguard.
* Generate the pre-shared key and the client key.
  ```
  # umask 0077
  # wg genpsk > /etc/wireguard/preshared.key
  # wg genkey | (umask 0077 && tee /etc/wireguard/private.key) | wg pubkey > /etc/wireguard/public.key
  ```
* Create the client configuration in `/etc/wireguard/wg0.conf`.
  ```
  [Interface]
  Address = <client-ip-address-inside-the-vpn>/32
  PrivateKey = <client-private-key>

  [Peer]
  PublicKey = <server-public-key>
  PresharedKey = <preshared-key>
  Endpoint = <server-public-ip-address>:<server-vpn-port>
  AllowedIPs = <server-ip-address-inside-the-vpn>/32
  ```
* Change the configuration ownership and permissions:
  ```
  # chown root:root /etc/wireguard/wg0.conf
  # chmod 600 /etc/wireguard/wg0.conf
  ```


### Client, allow access to the other peers

* Replace the `AllowedIPs` clause by
  ```
  AllowedIPs = <vpn-subnet>
  ```


### Client, full tunneling

* Assumes that a DNS resolver is running on the server.
* Add the following under `[Interface]` in `/etc/wireguard/wg0.conf`:
  ```
  DNS = <server-ip-address-inside-the-vpn>
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
  PostUp = resolvectl dns %i <server-ip-address-inside-the-vpn>; resolvectl domain %i "~."; resolvectl default-route %i true
  PreDown = resolvectl revert %i
  ```


### Server

* Insert the client to the server configuration.
  ```
  [Peer]
  PublicKey = <client-public-key>
  PresharedKey = <preshared-key>
  AllowedIPs = <client-ip-address-inside-the-vpn>/32
  ```


## git

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
