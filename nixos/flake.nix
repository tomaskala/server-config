{
  description = "Network infrastructure";

  nixConfig.bash-prompt = "[nix-develop]$ ";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    agenix.url = "github:ryantm/agenix";

    vps-admin-os.url = "github:vpsfreecz/vpsadminos";

    unbound-blocker.url = "github:tomaskala/unbound-blocker";
  };

  outputs = { self, nixpkgs, agenix, vps-admin-os, unbound-blocker }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];

      forOneSystem = f: system:
        f (import nixpkgs {
          inherit system;
          overlays = [
            (_: _: {
              unbound-blocker = unbound-blocker.packages.${system}.default;
            })
          ];
        });

      forAllSystems = f: nixpkgs.lib.genAttrs systems (forOneSystem f);
    in {
      nixosConfigurations = {
        whitelodge = let system = "x86_64-linux";
        in nixpkgs.lib.nixosSystem {
          inherit system;

          pkgs = forOneSystem (pkgs: pkgs) system;

          modules = [
            ./machines/whitelodge/configuration.nix
            agenix.nixosModules.default
            vps-admin-os.nixosConfigurations.container
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
