# Infrastructure configuration

Configuration for my network infrastructure.

## Deployment

To deploy a machine (called `twinpeaks` in this example), do the following.

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
7. Clone this repository to the machine.
8. Copy all secrets into `/root/secrets` on the machine.
9. Symlink `flake.nix` to `/etc/nixos/flake.nix`.
10. Enter a Nix shell with git, because the flake setup needs it.
    ```
    $ nix-shell -p git
    ```
11. Run
    ```
    # nixos-rebuild --switch --flake '<path-to-repo>#twinpeaks'
    ```
    Explicitly setting the flake is only necessary during the initial 
    deployment. Afterwards, the hostname will have been set and `nixos-rebuild` 
    will automatically select the matching flake.

## Adding a new secret

1. Put it into `secrets.nix` (prefixed with `twinpeaks-`) and assign a key.
2. Add it into `machines/twinpeaks/secrets-management.nix` (_not_ prefixed with 
   `twinpeaks-`).
3. Edit it with `agenix -e <secret.age>`.

Note: Prefixing each secret by the hostname in `secrets.nix` prevents conflicts 
in case multiple machines want to use a secret with the same name (e.g. 
`users-tomas-password`). The hostname prefix is automatically put in place to 
the file names in `secrets-management.nix`, but not to the Nix variables. That 
in turn allows sharing configurations between machines, reusing the secret 
name, but not the secret itself.
