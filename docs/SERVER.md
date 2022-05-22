# Server configuration

Configuration for the `server` group. Assumes Debian 11.


## First login

The first login is done under the `root` user. The admin user is created and
python is installed, so that ansible can be run afterwards.
```
# apt install sudo python3
# useradd -m -s /bin/bash -G sudo <admin-username>
# passwd <admin-username>
```


## Copy the admin user public key

```
$ ssh-copy-id -i <admin-user-public-key> <server-address>
```


## Server configuration

Before the VPN is set up and the SSH config alias can be used, the server
address must be overridden to its public address.


### Initialize and secure the server

```
$ ansible-playbook -t init,security -e "ansible_host=<server-address>" dale.yml
```


### Setup services

```
$ ansible-playbook -t services dale.yml
```
