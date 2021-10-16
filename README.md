# VPS setup

Configuration for my VPS. Assumes Debian 10.


## Initial configuration

At first, some minimal configuration is needed.


### Basic setup

* Update the system.
  ```
  $ apt update && apt upgrade
  ```
* Change the root password.
  ```
  $ passwd root
  ```
* Create a user.
  ```
  $ apt install sudo
  $ useradd -m -G sudo -s /bin/bash <username>
  $ passwd <username>
  $ chmod 700 /home/<username>
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
* Copy [sshd_config](sshd_config) to `/etc/ssh/sshd_config` on the server.
* Deactivate short Diffie-Hellman moduli.
  ```
  $ awk '$5 >= 3071' /etc/ssh/moduli | sudo tee /etc/ssh/moduli.tmp > /dev/null && sudo mv /etc/ssh/moduli.tmp /etc/ssh/moduli
  $ sudo service sshd restart
  ```
* Relog.


### Setup a firewall

```
$ sudo apt install nftables
$ sudo systemctl enable --now nftables.service
```
* Copy [nftables.conf](nftables.conf) to `/etc/nftables.conf` on the server.
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
* Copy [nginx](nginx) to `/etc/nginx/` on the server. **Do not forget to
  replace `<YOUR-DOMAIN>` with your domain and `<DNS-SERVER-1>` and
  `<DNS-SERVER-2>` with the DNS servers your server is using. Also rename
  [nginx/sites-available/YOUR-DOMAIN.conf](nginx/sites-available/YOUR-DOMAIN.conf)
  based on your domain.**
* The configuration is based on the [Mozilla SSL Configuration
  Generator](https://ssl-config.mozilla.org/).
  ```
  $ sudo rm /etc/nginx/sites-enabled/default /etc/nginx/sites-available/default
  $ sudo ln -s /etc/nginx/sites-available/YOUR-DOMAIN.conf /etc/nginx/sites-enabled/
  $ sudo nginx -t  # Verify that there are no errors in the config.
  $ sudo systemctl enable --now nginx
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
$ useradd -r -m -U -d /home/git -s /bin/bash git
$ passwd git

# Allow the main user to access the git directory and to initialize repos.
$ chmod 755 /home/git
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
  $ useradd -r -m -U -d /home/storage -s /bin/bash storage
  $ passwd storage

  # Allow the main user to access the rsync directory and to initialize dirs.
  $ chmod 755 /home/storage
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
