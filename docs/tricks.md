# Various Nix tricks

- Get the NixOS configuration into the REPL:
  - Non-flakes:
    ```
    $ nix repl -I nixos-config=/path/to/configuration.nix -f <nixpkgs/nixos>
    ```
  - Flakes, assuming you are in the flake root:
    ```
    $ nix repl
    nix-repl> :lf .
    nix-repl> nixosConfigurations.hostname.<attribute>
    ```
