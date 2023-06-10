# Infrastructure configuration

Configuration for my network infrastructure.

## Deployment

To deploy a machine (called `twinpeaks` in this example), do the following.

1. Put its configuration under `machines/twinpeaks`.
2. Create an `outputs.nixosConfigurations.twinpeaks` block in `flake.nix`.
3. Start the machine and its SSH server to generate an SSH host key.
4. Obtain the host key using `ssh-keyscan <ip-address>`.
5. Put the host key and any secrets inside `secrets.nix`.
6. Define all secrets by running `agenix -e <secret.age>`.
7. Clone this repository to the machine.
8. Copy all secrets into `/root/secrets` on the machine.
9. Symlink `flake.nix` to `/etc/nixos/flake.nix`.
10. Run `nixos-rebuild --switch --flake '/etc/nixos#twinpeaks'`. Explicitly 
    setting the flake is only necessary during the initial deployment. 
    Afterwards, the hostname will have been set and `nixos-rebuild` will 
    automatically select the matching flake.

## Adding a new secret

1. Put it into `secrets.nix` and assign a key.
2. Add it into `machines/twinpeaks/secrets-management.nix`.
3. Edit it with `agenix -e <secret.age>`.
