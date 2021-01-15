# VPS setup

Configuration for my VPS. Assumes Debian 10.

1. **Update the system.**
    ```
    $ apt update && apt upgrade
    ```
2. **Change the root password.**
    ```
    $ passwd root
    ```
3. **Add users.**
    * A sudo user.
      ```
      $ apt install sudo
      $ adduser <username>
      $ passwd <username>
      $ usermod -aG sudo <username>
      ```
    * An unprivileged user for `git`. The command below creates a system
      account called 'git' and adds it to a group with the same name.
      Additionally, it creates a given home directory and sets the shell. The
      setup of `git` itself, along with disabling shell access, is addressed
      later.
      ```
      $ useradd -r -m -U -d /home/git -s /bin/bash git
      $ passwd git
      ```
    * Setup access rights for the users' home directories. We keep 755 for the
      git user to be able to access its home directory and initialize
      repositories.
      ```
      $ chmod 700 /home/<username>
      $ chmod 755 /home/git
      ```
4. **Log out, transfer the SSH key(s).**
    ```
    $ ssh-copy-id -i ~/.ssh/<public-key> <username>@<host>
    $ ssh-copy-id -i ~/.ssh/<public-key-git> git@<host>
    ```
5. **Log in as the newly created user.**
    * Change permissions for the authorized keys files.
      ```
      $ sudo chmod 600 /home/<username>/.ssh/authorized_keys
      $ sudo chmod 600 /home/git/.ssh/authorized_keys
      ```
6. **Configure SSH.**
    * The configuration involves changing the default SSH port from 22 to deter
      dumb bots.
    * The settings are based on the [Mozilla OpenSSH
      guidelines](https://infosec.mozilla.org/guidelines/openssh). Only
      non-default settings are included.
    * Copy [sshd_config](sshd_config) to `/etc/ssh/sshd_config` on the server.
      **Do not forget to replace `<NEW-SSH-PORT>` with the correct value and
      `<USERNAME>` with your main account username!**
    * Deactivate short Diffie-Hellman moduli.
      ```
      $ awk '$5 >= 3071' /etc/ssh/moduli \
        | sudo tee /etc/ssh/moduli.tmp > /dev/null \
        && sudo mv /etc/ssh/moduli.tmp /etc/ssh/moduli
      $ sudo service sshd restart
      ```
    * Relog.
7. **Set up a firewall.**
    ```
    $ sudo apt install nftables
    $ sudo systemctl start nftables.service
    $ sudo systemctl enable nftables.service
    ```
    * Copy [nftables.conf](nftables.conf) to `/etc/nftables.conf` on the
      server. **Do not forget to replace `<NEW-SSH-PORT>` with the correct
      value!**
    ```
    $ sudo nft -f /etc/nftables.conf
    ```
8. **Install `fail2ban`.**
    ```
    $ sudo apt install fail2ban
    ```
    * Copy [fail2ban](fail2ban) to `/etc/fail2ban` on the server. **Do not
      forget to replace `<NEW-SSH-PORT>` in [jail.local](fail2ban/jail.local)
      with the correct value!**
      ```
      $ sudo cp /etc/fail2ban/filter.d/apache-badbots.conf \
        /etc/fail2ban/filter.d/nginx-badbots.conf
      ```
    * Check `/etc/fail2ban/action.d/` whether `nftables.conf` exists. If yes,
      replace the `[DEFAULT]` section in [jail.local](fail2ban/jail.local) with
      the following.
      ```
      [DEFAULT]
      banaction = nftables
      banaction_allports = nftables[type=allports]
      ```
    ```
    $ sudo systemctl start fail2ban
    $ sudo systemctl enable fail2ban
    $ sudo fail2ban-client status  # Check fail2ban status.
    $ sudo fail2ban-client status sshd  # Check the SSH jail status.
    ```
9. **Enable SSH 2FA.**
    * Make sure that the currently logged user is the one we are setting 2FA
      for.
      ```
      $ sudo apt install libpam-google-authenticator
      $ google-authenticator
      $ sudo cp --archive /etc/pam.d/sshd \
        /etc/pam.d/sshd-COPY-$(date +"%Y%m%d%H%M%S")  # Backup PAM SSH config.
      ```
    * `$ sudo vim /etc/pam.d/sshd`
        * Comment out the `@include common-auth` line.
        * Add `auth required pam_google_authenticator.so` to the bottom of the
          file.
    * `$ sudo vim /etc/ssh/sshd_config`
        * `ChallengeResponseAuthentication yes`
        * `AuthenticationMethods publickey,keyboard-interactive`
        * The first line makes SSH use PAM. The second line requires both the
          SSH key and the verification code -- by default, the SSH key would be
          sufficient.
    ```
    $ sudo service sshd restart
    ```
10. **Enable automatic updates.**
    ```
    $ sudo apt install unattended-upgrades
    ```
    * `$ sudo vim /etc/apt/apt.conf.d/20auto-upgrades`
      ```
      APT::Periodic::Update-Package-Lists "1";
      APT::Periodic::Unattended-Upgrade "1";
      ```
    * `$ sudo vim /etc/apt/apt.conf.d/50unattended-upgrades`
      ```
      Unattended-Upgrade::Origins-Pattern {
          "origin=Debian,codename=${distro_codename},label=Debian-Security";
      };
      ```
11. **Install `nginx` and setup an SSL certificate using [Let's
Encrypt](https://letsencrypt.org/).**
    * This assumes that a domain has been registered for the server. If not, it
      is possible to setup a self-signed certificate to encrypt the connection,
      though obviously without any verification.
    * In the `certbot` command below, you will be asked to enter your domain
      name. From now on, this will be referred to as `YOUR-DOMAIN`. We generate
      a certificate but do not modify the nginx config, because it would
      overwrite our settings. We also generate a 2048 bits-long Diffie-Hellman
      parameter.
      ```
      $ sudo apt update
      $ sudo apt install nginx certbot python-certbot-nginx
      $ sudo certbot certonly --nginx
      $ sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048
      ```
    * Copy [nginx](nginx) to `/etc/nginx/` on the server. **Do not forget to
      replace `<YOUR-DOMAIN>` with your domain and `<DNS-SERVER-1>` and
      `<DNS-SERVER-2>` with the DNS servers your server is using. Also rename
      [nginx/sites-available/YOUR-DOMAIN.conf](nginx/sites-available/YOUR-DOMAIN.conf)
      based on your domain.**
    * The configuration is based on the [Mozilla SSL Configuration
      Generator](https://ssl-config.mozilla.org/).
      ```
      $ sudo rm /etc/nginx/sites-enabled/default \
        /etc/nginx/sites-available/default
      $ sudo ln -s /etc/nginx/sites-available/YOUR-DOMAIN.conf \
        /etc/nginx/sites-enabled/
      $ sudo nginx -t  # Verify that there are no errors in the config.
      $ sudo certbot renew --dry-run  # Verify certbot auto-renewal.
      $ sudo systemctl start nginx
      $ sudo systemctl enable nginx
      $ sudo systemctl restart fail2ban
      $ sudo fail2ban-client status
      ```
    * Optionally, you can use the [Qualys SSL Server
      Test](https://www.ssllabs.com/ssltest/) to check your configuration.
12. **Setup `git`.**
    ```
    $ sudo apt install git
    ```
    * This section works with the git user created earlier.
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
    * Strongly recommended SSH configuration on the local computer (i.e., not
      the server).
        * Put this into `~/.ssh/config`.
          ```
          Host vps-git
              User git
              Hostname <YOUR-DOMAIN>
              Port <NEW-SSH-PORT>
              IdentitiesOnly yes
              IdentityFile ~/.ssh/<PRIVATE-KEY-GIT>
          ```
        * This configuration allows to simplify git queries to the server. It
          is no longer necessary to specify the different SSH port and it is
          possible to use a unique SSH key. Furthermore, `IdentitiesOnly yes`
          ensures that SSH will not try all your keys but immediately use the
          specified one.
    * The following is a template to initialize a new git repository on the
      server. This must be repeated for each new repository.
        * On the server side, logged as the main user (the git user does not
          have a proper shell, so login is impossible anyway).
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
        * Alternatively, you can initialize an empty Git repository and point
          it to the server.
          ```
          $ cd <REPO-DIRECTORY>
          $ git init
          $ touch README.md
          $ git add -A
          $ git commit -m "Initial commit"
          $ git remote add origin vps-git:<REPO-NAME>.git
          $ git push origin master
          ```
