# Infrastructure configuration

Configuration for my network infrastructure.

## Deployment

To define and deploy a machine (called `twinpeaks` in this example), do the 
following.

1. Put its configuration under `machines/twinpeaks`.
2. Create an `outputs.nixosConfigurations.twinpeaks` block in `flake.nix`.
3. Start the machine and its SSH server to generate an SSH host key.
4. Obtain the host key.
   ```
   $ ssh-keyscan <ip-address>
   ```
5. Put the host key and any secrets inside `secrets.nix`.
6. Define all secrets.
   ```
   $ nix run github:ryantm/agenix -- -e <secret.age>
   ```
7. Copy all secrets into `/root/secrets` on the machine.
8. SSH into the machine and enter a Nix shell with git (the flake setup needs 
   it).
   ```
   $ nix shell nixpkgs#git
   ```
9. Run
   ```
   # nixos-rebuild --switch --flake 'github:tomaskala/infra#twinpeaks'
   ```
   Explicitly setting the flake is only necessary during the initial 
   deployment. Afterwards, the hostname will have been set and `nixos-rebuild` 
   will automatically select the matching flake.

## Adding a new secret

1. Put it into `secrets.nix` and assign an encryption key.
2. Add it into `machines/twinpeaks/secrets-management.nix`.
3. Edit it with `agenix -e <secret.age>`.
