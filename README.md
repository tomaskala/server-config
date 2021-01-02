# VPS initial setup
Configuration for my VPS. Assumes Debian 10.

1. **Update the system.**
    * `apt update && apt upgrade`
2. **Change the root password.**
    * `passwd root`
3. **Create a non-root user, grant sudo privileges.**
    * `apt install sudo`
    * `adduser <username>`
    * `passwd <username>`
    * `usermod -aG sudo <username>`
4. **Log out, transfer the SSH key.**
    * `ssh-copy-id -i ~/.ssh/<public-key> <username>@<host>`
5. **Log in as the newly created user.**
6. **Configure SSH.**
    * `sudo vim /etc/ssh/sshd_config`
        * `PermitRootLogin no`
        * `PasswordAuthentication no`
        * `Port <NEW-SSH-PORT>`
        * `LogLevel VERBOSE`
        * `KexAlgorithms curve25519-sha256@libssh.org,ecdh-sha2-nistp521,ecdh-sha2-nistp384,ecdh-sha2-nistp256,diffie-hellman-group-exchange-sha256`
        * `Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr`
        * `MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,umac-128@openssh.com`
    * `sudo service sshd restart`.
    * Relog.
    * Note: The cipher settings are taken from [this document](https://infosec.mozilla.org/guidelines/openssh#Modern_.28OpenSSH_6.7.2B.29).
7. **Set up a firewall.**
    * `sudo apt install nftables`
    * `sudo systemctl start nftables.service`
    * `sudo systemctl enable nftables.service`
    * Copy [nftables.conf](nftables.conf) to `/etc/nftables.conf` on the server. **Do not forget to replace `<NEW-SSH-PORT>` with the correct value!**
    * `sudo nft -f /etc/nftables.conf`
8. **Install `fail2ban`.**
    * `sudo apt install fail2ban`
    * Copy [fail2ban](fail2ban) to `/etc/fail2ban` on the server. **Do not forget to replace `<NEW-SSH-PORT>` in [jail.local](fail2ban/jail.local) with the correct value!**
    * `sudo cp /etc/fail2ban/filter.d/apache-badbots.conf /etc/fail2ban/filter.d/nginx-badbots.con`
        * Check `/etc/fail2ban/action.d/` whether `nftables.conf` exists. If yes, replace the `[DEFAULT]` section in [jail.local](fail2ban/jail.local) with the following.
        ```
        [DEFAULT]
        banaction = nftables
        banaction_allports = nftables[type=allports]
        ```
    * `sudo systemctl start fail2ban`
    * `sudo systemctl enable fail2ban`
    * Check `fail2ban` status: `sudo fail2ban-client status`.
    * Check the SSH jail status: `sudo fail2ban-client status sshd`.
9. **Enable SSH 2FA.**
    * `sudo apt install libpam-google-authenticator`.
    * Make sure that the currently logged user is the one we are setting 2FA for.
    * Run `google-authenticator` (without `sudo`).
    * Make a backup of the PAM SSH config: `sudo cp --archive /etc/pam.d/sshd /etc/pam.d/sshd-COPY-$(date +"%Y%m%d%H%M%S")`.
    * `sudo vim /etc/pam.d/sshd`
        * Comment out the `@include common-auth` line.
        * Add `auth required pam_google_authenticator.so` to the bottom of the file.
    * `sudo vim /etc/ssh/sshd_config`
        * `ChallengeResponseAuthentication yes`
        * `AuthenticationMethods publickey,keyboard-interactive`
        The first line makes SSH use PAM. The second line requires both the SSH key and the verification code -- by default, the SSH key would be sufficient.
    * Restart SSH: `sudo service sshd restart`.
10. **Enable automatic updates.**
    * `sudo apt install unattended-upgrades`
    * `sudo vim /etc/apt/apt.conf.d/20auto-upgrades`
    ```
    APT::Periodic::Update-Package-Lists "1";
    APT::Periodic::Unattended-Upgrade "1";
    ```
    * `sudo vim /etc/apt/apt.conf.d/50unattended-upgrades`
    ```
    Unattended-Upgrade::Origins-Pattern {
            "origin=Debian,codename=${distro_codename},label=Debian-Security";
    };
    ```
11. **Install `nginx`.**
    * `sudo apt install nginx`
    * Setup denial of service protection.
        * `sudo vim /etc/nginx/nginx.conf`
        * Add the following under `http`.
        ```
        limit_req_zone $binary_remote_addr zone=one:10m rate=1r/s;
        limit_req zone=one burst=5;
        ```
        * This defines a zone called `one` sized 10MB and limits its processing rate to a given number of requests/second/key, the key being the client IP address.
        * When the rate is exceeded, additional requests are delayed until their number reaches the burst size, at which point 503 (Service Unavailable) is returned instead.
        * Works with `nginx-limit-req` in the `fail2ban` configuration.
    * `sudo systemctl start nginx`
    * `sudo systemctl enable nginx`
    * `sudo systemctl restart fail2ban`
    * `sudo fail2ban-client status`
12. **Setup an SSL certificate.**
    * This assumes that a domain has been registered for the server. If not, it is possible to setup a self-signed certificate to encrypt the connection, though obviously without any verification.
    * Use [Let's Encrypt](https://letsencrypt.org/) to generate a certificate.
        * `sudo apt update`
        * `sudo apt install certbot python-certbot-nginx`
        * In the command below, you are asked to enter your domain name. From now on, this will be referred to as `YOUR-DOMAIN`.
        * `sudo certbot certonly --nginx`
    * Generate a Diffie-Hellman parameter.
        * `sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048`
    * Copy [YOUR-DOMAIN.conf](YOUR-DOMAIN.conf) to `/etc/nginx/sites-available/YOUR-DOMAIN.conf` on the server. **Do not forget to replace `YOUR-DOMAIN` with your domain, both in the filename and its contents!**
    * `sudo rm /etc/nginx/sites-enabled/default /etc/nginx/sites-available/default`
    * `sudo ln -s /etc/nginx/sites-available/YOUR-DOMAIN.conf /etc/nginx/sites-enabled/`
    * Verify that there are no errors in the config: `sudo nginx -t`.
    * Verify `certbot` auto-renewal: `sudo certbot renew --dry-run`.
        * Also check the related cronjob at `/etc/cron.d/certbot`.
    * `sudo systemctl restart nginx`
    * Optionally, you can use the [Qualys SSL Server Test](https://www.ssllabs.com/ssltest/) to check your configuration.
13. Grafana
    * (Fail2ban](https://community.grafana.com/t/how-can-we-set-up-fail2ban-to-protect-our-dashboard/21962/10)
    * [nginx proxy](https://serverfault.com/questions/684709/how-to-proxy-grafana-with-nginx)
14. Nextcloud
    * Fail2ban setup is described in the official documentation, section server hardening.
