{
  description = "Network infrastructure";
  nixConfig.bash-prompt = "[nix-develop]$ ";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:nixos/nixos-hardware/master";
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
        config = {
          system.stateVersion = stateVersion;

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
              in [ (_: _: { inherit (unstable) blocky mealie; }) ];
          };
        in nixpkgs.lib.nixosSystem {
          inherit system pkgs;

          modules = [
            ./machines/whitelodge/configuration.nix
            (commonConfig "23.05")
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
            (commonConfig "23.05")
            nixos-hardware.nixosModules.raspberry-pi-4
            agenix.nixosModules.default
          ];

          specialArgs = {
            inherit secrets;
            util = mkUtil pkgs;
          };
        };
      };

      darwinConfigurations = {
        cooper = let
          system = "aarch64-darwin";
          pkgs = import nixpkgs {
            inherit system;
            overlays =
              let unstable = import nixpkgs-unstable { inherit system; };
              in [ (_: _: { inherit (unstable) neovim; }) ];
          };
        in nix-darwin.lib.darwinSystem {
          inherit system pkgs;

          modules = [ ./machines/cooper/configuration.nix (commonConfig 4) ];
        };
      };

      packages.x86_64-linux.audrey =
        let pkgs = nixpkgs.legacyPackages.x86_64-linux;
        in pkgs.callPackage ./machines/audrey { inherit openwrt-imagebuilder; };

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
        deadnix = pkgs.callPackage ./checks/deadnix.nix { };
        statix = pkgs.callPackage ./checks/statix.nix { };
        nixfmt = pkgs.callPackage ./checks/nixfmt.nix { };
      });
    };
}
