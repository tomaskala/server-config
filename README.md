# VPS initial setup
A short checklist to perform when setting up a new VPS. Assumes that the first login is under the root user.

The guide assumes Debian 10 to be running on the VPS.

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
        * `Port <new-ssh-port>`
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
    * Copy [nftables.conf](nftables.conf) to `/etc/nftables.conf` on the server. **Do not forget to replace `<new-ssh-port>` with the correct value!**
    * `sudo nft -f /etc/nftables.conf`
8. **Install `fail2ban`.**
    * `sudo apt install fail2ban`
    * `sudo vim /etc/fail2ban/jail.local`
    ```
    [DEFAULT]
    banaction = nftables
    banaction_allports = nftables[type=allports]

    [sshd]
    enabled = true
    port = <new-ssh-port>
    bantime = 2w
    maxretry = 5
    ```
    With older `fail2ban` versions, the `[DEFAULT]` section should contain the following instead.
    ```
    [DEFAULT]
    banaction = nftables-common
    banaction_allports = nftables-allports
    ```
    Check `/etc/fail2ban/action.d/` whether `nftables.conf` exists. If yes, use the former `[DEFAULTS]`, otherwise, use the latter.
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


## TODO
* Let's Encrypt HTTPS?
* Nextcloud fail2ban 
    * **Nevermind, check out the nextcloud documentation, server hardening section.**
    * The configuration below is likely outdated. Check also [this link](https://help.nextcloud.com/t/fail2ban-nextclouds-log-expression-chaged/59481).
    * [This link](https://www.c-rieger.de/nextcloud-installationsanleitung/) is probably better, though auf Deutsch.
    * Create filter `sudo vim /etc/fail2ban/filter.d/nextcloud.conf`
    ```
    [Definition]
    failregex=^{"reqId":".","remoteAddr":".","app":"core","message":"Login failed: '.' (Remote IP: '')","level":2,"time":"."}$
    ^{"reqId":".","level":2,"time":".","remoteAddr":".","app":"core".","message":"Login failed: '.' (Remote IP: '')".}$
    ^.\"remoteAddr\":\"\".Trusted domain error.*$
    ```
    The first two check for login failures & flag the source IP. The third checks for trusted domain errors (bots accessing via IP, not the domain).

    Check it: `sudo fail2ban-regex /var/nextcloud/data/nextcloud.log /etc/fail2ban/filter.d/nextcloud.conf -v`
    * Create jail `sudo vim /etc/fail2ban/jail.d/nextcloud.local`
    ```
    [nextcloud]
    enabled = true
    banaction = ufw
    port = http,https
    filter = nextcloud
    logpath = /var/nextcloud/data/nextcloud.log
    maxretry = 3
    ignoreip = 192.168.1.0/24
    backend = auto
    protocol = tcp
    bantime = 36000
    findtime = 36000
    ```
    * Then
    ```
    sudo fail2ban-client add nextcloud
    sudo fail2ban-client restart
    ```
    and check status as above.
* In case ssh key transfer does not go as expected.
    * `su - <username>`
    * `mkdir ~/.ssh`
    * `chmod 700 ~/.ssh`
    * `touch ~/.ssh/authorized_keys`, paste the SSH public key inside.
    * `chmod 600 ~/.ssh/authorized_keys`
