# infra

Configuration for my network infrastructure.

## Machines

- `whitelodge`: My VPS running NixOS.
- `blacklodge`: My desktop computer running Pop!_OS.
- `cooper`: Lenovo Thinkpad T14 Gen 2 running Arch Linux.
- `gordon`: MacBook Air M3.
- `bob`: Raspberry Pi 4 Model B running NixOS.
- `hawk`: iPhone SE 2022.
- `audrey`: MikroTik hAP ac lite TC running OpenWRT.

## Deployment

To define and deploy a machine (called `twinpeaks` in this example), do the 
following.

1. Put its configuration under `machines/twinpeaks`.
2. Create an `outputs.nixosConfigurations.twinpeaks` block in `flake.nix`. If 
   necessary, define its network configuration in `intranet/devices.nix` and 
  `intranet/wireguard.nix`.
3. Start the machine and its SSH server to generate an SSH host key.
4. Obtain the host key.
   ```
   $ ssh-keyscan <ip-address>
   ```
5. Follow the instructions in the 
   [infra-secrets](https://github.com/tomaskala/infra-secrets) repository.
6. SSH into the machine and enter a Nix shell with git (the flake setup needs 
   it).
   ```
   $ nix shell nixpkgs#git
   ```
7. Run
   ```
   # nixos-rebuild switch --flake 'github:tomaskala/infra#twinpeaks'
   ```
   Explicitly setting the flake is only necessary during the initial 
   deployment. Afterwards, the hostname will have been set and `nixos-rebuild` 
   will automatically select the matching flake.
