# Raspberry Pi configuration

Configuration for the `raspberry` group. Assumes Raspbian 11.


## Raspbian setup

* Download Raspberry Pi OS Lite (64-bit).
* Verify the SHA-256 signature.
  * Create a file called `SHA256SUM` with the following structure.
    ```
    <sha-256-sum> <raspbian-image.xz>
    ```
  * Run
    ```
    $ sha256sum -c SHA256SUM
    ```
* Write the image to an SD card.
  ```
  # xz -dc <raspbian-image.xz> | dd of=/dev/<sd-card> bs=4M conv=fsync status=progress && sync
  ```
* Initialize the system.
  * Mount the SD card.
  * In the boot partition, create:
    * An empty file called `ssh`.
    * A file called `userconf.txt` with the following structure.
      ```
      <admin-username>:<password-hash>
      ```
      where the password hash can be obtained by running
      ```
      $ echo '<password>' | openssl passwd -6 -stdin
      ```
* Start the machinae.
* Run
  ```
  # raspi-config
  ```
  and reboot the system afterwards.


## Copy the admin user public key

```
$ ssh-copy-id -i <admin-user-public-key> <raspberry-address>
```


## Configuration

* Install [log2ram](https://github.com/azlux/log2ram).
* Disable wifi and bluetooth.
  * Add the following to `/boot/config.txt`.
    ```
    # Disable wifi and bluetooth.
    dtoverlay=disable-wifi
    dtoverlay=disable-bt
    ```
  * Run
    ```
    # systemctl disable hciuart
    ```
  * Reboot.
* Run the playbook.
  ```
  $ ansible-playbook bob.yml
  $ ansible-playbook mike.yml
  ```
