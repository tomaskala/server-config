{
  description = "Network infrastructure";
  nixConfig.bash-prompt = "[nix-develop]$ ";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nixos-hardware.url = "github:nixos/nixos-hardware/master";
    vps-admin-os.url = "github:vpsfreecz/vpsadminos";

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    secrets = {
      url = "git+ssh://git@github.com/tomaskala/infra-secrets";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    unbound-blocker = {
      url = "github:tomaskala/unbound-blocker";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nixos-hardware, vps-admin-os, agenix, secrets
    , unbound-blocker, ... }:
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
        whitelodge = let
          system = "x86_64-linux";
          pkgs = forOneSystem (pkgs: pkgs) system;
          util =
            forOneSystem (pkgs: import ./util { inherit (pkgs) lib; }) system;
        in nixpkgs.lib.nixosSystem {
          inherit system pkgs;
          modules = [
            ./machines/whitelodge/configuration.nix
            commonConfig
            agenix.nixosModules.default
            vps-admin-os.nixosConfigurations.container
          ];
          specialArgs = { inherit secrets util; };
        };

        bob = let
          system = "aarch64-linux";
          pkgs = forOneSystem (pkgs: pkgs) system;
          util =
            forOneSystem (pkgs: import ./util { inherit (pkgs) lib; }) system;
        in nixpkgs.lib.nixosSystem {
          inherit system pkgs;
          modules = [
            ./machines/bob/configuration.nix
            commonConfig
            nixos-hardware.nixosModules.raspberry-pi-4
            agenix.nixosModules.default
          ];
          specialArgs = { inherit secrets util; };
        };
      };

      devShells = forAllSystems (pkgs: {
        default =
          pkgs.mkShell { packages = with pkgs; [ deadnix nixfmt statix ]; };

        tf = pkgs.mkShell { packages = [ pkgs.opentofu ]; };
      });

      formatter = forAllSystems (pkgs:
        pkgs.writeShellApplication {
          name = "nixfmt";
          runtimeInputs = with pkgs; [ findutils nixfmt ];
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
