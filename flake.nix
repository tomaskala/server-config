{
  description = "Network infrastructure";
  nixConfig.bash-prompt = "[nix-develop]$ ";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    vps-admin-os.url = "github:vpsfreecz/vpsadminos";

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    openwrt-imagebuilder = {
      url = "github:astro/nix-openwrt-imagebuilder";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    secrets = {
      url = "git+ssh://git@github.com/tomaskala/infra-secrets";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nixpkgs-unstable, nixos-hardware, vps-admin-os
    , nix-darwin, home-manager, agenix, openwrt-imagebuilder, secrets, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];

      commonConfig = stateVersion: {
        system.stateVersion = stateVersion;

        nixpkgs.overlays = [
          (final: prev: {
            unstable = nixpkgs-unstable.legacyPackages.${prev.system};
            util = import ./util { inherit (final.pkgs) lib; };
          })
        ];

        nix = {
          # Pin the nixpkgs flake to the same exact version used to build
          # the system. This has two benefits:
          # 1. No version mismatch between system packages and those
          #    brought in by commands like 'nix shell nixpkgs#<package>'.
          # 2. More efficient evaluation, because many dependencies will
          # already be present in the Nix store.
          registry.nixpkgs.flake = nixpkgs;

          settings = {
            auto-optimise-store = true;
            experimental-features = [ "nix-command" "flakes" ];
          };
        };
      };

      forAllSystems = f:
        nixpkgs.lib.genAttrs systems
        (system: f nixpkgs.legacyPackages.${system});
    in {
      nixosConfigurations = {
        whitelodge = nixpkgs.lib.nixosSystem {
          # TODO: Unstable blocky
          system = "x86_64-linux";

          modules = [
            (commonConfig "23.05")
            ./machines/whitelodge/configuration.nix
            agenix.nixosModules.default
            home-manager.nixosModules.home-manager
            vps-admin-os.nixosConfigurations.container
          ];

          specialArgs = { inherit secrets; };
        };

        bob = nixpkgs.lib.nixosSystem {
          # TODO: Unstable blocky
          system = "aarch64-linux";

          modules = [
            (commonConfig "23.05")
            ./machines/bob/configuration.nix
            agenix.nixosModules.default
            nixos-hardware.nixosModules.raspberry-pi-4
          ];

          specialArgs = { inherit secrets; };
        };
      };

      darwinConfigurations = {
        cooper = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";

          modules = [ (commonConfig 4) ./machines/cooper/configuration.nix ];
        };
      };

      packages.x86_64-linux.audrey = import ./machines/audrey {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        inherit openwrt-imagebuilder;
      };

      devShells = forAllSystems (pkgs: {
        default = import ./shells/infra.nix { inherit pkgs; };
        work = import ./shells/work.nix { inherit pkgs; };
      });

      formatter = forAllSystems (pkgs:
        pkgs.writeShellApplication {
          name = "nixfmt";
          runtimeInputs = with pkgs; [ findutils nixfmt-classic ];
          text = ''
            find . -type f -name '*.nix' -exec nixfmt {} \+
          '';
        });

      checks = forAllSystems (pkgs: {
        deadnix = import ./checks/deadnix.nix { inherit pkgs; };
        statix = import ./checks/statix.nix { inherit pkgs; };
        nixfmt = import ./checks/nixfmt.nix { inherit pkgs; };
      });
    };
}
