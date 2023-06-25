# NixOS on Raspberry Pi 4B

1. Download an SD card image from 
   <https://nixos.wiki/wiki/NixOS_on_ARM#Installation> and flash it on an SD 
   card.
2. Set a password for the default `nixos` user. Otherwise, you won't be able to 
   SSH in.
3. Boot the machine, SSH in, and run
   ```
   # nixos-generate-config
   ```
   to get the hardware configuration file.
4. Enable Nix flakes and the SSH server by setting
   ```
   nix.settings.experimental-features = [ "nix-command" "flakes" ];
   services.openssh.enable = true;
   ```
   in the generated `/etc/nixos/configuration.nix`. This sounds strange since 
   you're currently connected over SSH, but once we rebuild the machine, the 
   SD card image configuration that includes the SSH server definition will be 
   lost. Afterwards, rebuild the system:
   ```
   # nixos-rebuild switch
   ```
5. Update the firmware:
   ```
   # nix shell nixpkgs#raspberrypi-eeprom
   [nix-develop]$ mount /dev/disk/by-label/FIRMWARE /mnt
   [nix-develop]$ BOOTFS=/mnt FIRMWARE_RELEASE_STATUS=stable rpi-eeprom-update -d -a
   ```
   Afterwards, rebuild the machine.
6. Once booted up, make sure your system configuration includes the 
   `hardware-configuration.nix` file generated in step 3 and rebuild the 
   system.
   ```
   # nixos-rebuild switch --upgrade --flake 'github:tomaskala/infra#<hostname>'
   ```
