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

```
$ ansible-playbook -t init,security -i <server-address>, -e "target=<server-address> vpn_client_public_key=<vpn-client-public-key> vpn_client_preshared_key=<vpn-client-preshared-key> vpn_client=<vpn-client-address>" main.yml
```


### Setup services

```
$ ansible-playbook -t services main.yml
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
