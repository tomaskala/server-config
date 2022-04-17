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
new inventory (note the trailing comma).


### Initialize and secure the server

```
$ ansible-playbook -t init,security -i <server-address>, server.yml
```


### Setup services

```
$ ansible-playbook -t services server.yml
```
