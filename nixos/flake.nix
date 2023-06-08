{
  description = "Network infrastructure";

  nixConfig.bash-prompt = "[nix-develop]$ ";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    agenix.url = "github:ryantm/agenix";

    unbound-blocker.url = "github:tomaskala/unbound-blocker";
  };

  outputs = { self, nixpkgs, agenix, unbound-blocker }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];

      # TODO: This makes the overlays only accessible from the forAllSystems
      # function call. The nixosConfigurations members below do not use this
      # function, and hence do not have access to the overlays.
      # Possible fix: Define a function accepting a single system and producing
      # pkgs with the given system and overlay. The nixosConfigurations could
      # call it for a single system, and the forAllSystems function could call
      # it for each system.
      forAllSystems = f:
        nixpkgs.lib.genAttrs systems (system:
          f (import nixpkgs {
            inherit system;
            overlays = [
              (_: _: {
                unbound-blocker = unbound-blocker.packages.${system}.default;
              })
            ];
          }));
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
