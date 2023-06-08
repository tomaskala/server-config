{
  description = "Network infrastructure";

  nixConfig = { bash-prompt = "[nix-develop]$ "; };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    agenix.url = "github:ryantm/agenix";
  };

  outputs = { self, nixpkgs, agenix }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];

      forAllSystems = f:
        nixpkgs.lib.genAttrs systems
        (system: f nixpkgs.legacyPackages.${system});
    in {
      nixosConfigurations = {
        whitelodge = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";

          modules = [
            ./machines/whitelodge/configuration.nix
            agenix.nixosModules.default
          ];
        };
      };

      devShells = forAllSystems (pkgs: {
        default =
          pkgs.mkShell { packages = with pkgs; [ deadnix nixfmt statix ]; };
      });

      formatter = forAllSystems (pkgs:
        pkgs.writeShellApplication {
          name = "nixfmt";
          runtimeInputs = with pkgs; [ findutils nixfmt ];
          text = ''
            find . -type f -name '*.nix' -exec nixfmt {} \+
          '';
        });
    };
}
