{
  description = "Network infrastructure";
  nixConfig.bash-prompt = "[nix-develop]$ ";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:nixos/nixos-hardware/master";
    vps-admin-os.url = "github:vpsfreecz/vpsadminos";

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
    , home-manager, agenix, openwrt-imagebuilder, secrets, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];

      commonConfig = {
        config = {
          system.stateVersion = "23.05";

          # Pin the nixpkgs flake to the same exact version used to build
          # the system. This has two benefits:
          # 1. No version mismatch between system packages and those
          #    brought in by commands like 'nix shell nixpkgs#<package>'.
          # 2. More efficient evaluation, because many dependencies will
          # already be present in the Nix store.
          nix.registry.nixpkgs.flake = nixpkgs;
        };
      };

      mkUtil = pkgs: import ./util { inherit (pkgs) lib; };

      forAllSystems = f:
        nixpkgs.lib.genAttrs systems
        (system: f (import nixpkgs { inherit system; }));
    in {
      nixosConfigurations = {
        whitelodge = let
          system = "x86_64-linux";
          pkgs = import nixpkgs {
            inherit system;
            overlays =
              let unstable = import nixpkgs-unstable { inherit system; };
              in [ (_: _: { inherit (unstable) blocky; }) ];
          };
        in nixpkgs.lib.nixosSystem {
          inherit system pkgs;

          modules = [
            ./machines/whitelodge/configuration.nix
            commonConfig
            home-manager.nixosModules.home-manager
            agenix.nixosModules.default
            vps-admin-os.nixosConfigurations.container
          ];

          specialArgs = {
            inherit secrets;
            util = mkUtil pkgs;
          };
        };

        bob = let
          system = "aarch64-linux";
          pkgs = import nixpkgs {
            inherit system;
            overlays =
              let unstable = import nixpkgs-unstable { inherit system; };
              in [ (_: _: { inherit (unstable) blocky; }) ];
          };
        in nixpkgs.lib.nixosSystem {
          inherit system pkgs;

          modules = [
            ./machines/bob/configuration.nix
            commonConfig
            nixos-hardware.nixosModules.raspberry-pi-4
            agenix.nixosModules.default
          ];

          specialArgs = {
            inherit secrets;
            util = mkUtil pkgs;
          };
        };
      };

      packages.x86_64-linux.audrey =
        let pkgs = nixpkgs.legacyPackages.x86_64-linux;
        in pkgs.callPackage ./machines/audrey { inherit openwrt-imagebuilder; };

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [ deadnix nixfmt-classic statix ];
        };

        tf = pkgs.mkShell { packages = [ pkgs.opentofu ]; };
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
        deadnix = pkgs.callPackage ./checks/deadnix.nix { };
        statix = pkgs.callPackage ./checks/statix.nix { };
        nixfmt = pkgs.callPackage ./checks/nixfmt.nix { };
      });
    };
}
