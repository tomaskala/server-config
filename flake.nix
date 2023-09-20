{
  description = "Network infrastructure";
  nixConfig.bash-prompt = "[nix-develop]$ ";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    vps-admin-os.url = "github:vpsfreecz/vpsadminos";
    catppuccin.url = "github:catppuccin/nix";

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

      inputs = {
        nixpkgs.follows = "nixpkgs";
        darwin.follows = "nix-darwin";
        home-manager.follows = "home-manager";
      };
    };

    openwrt-imagebuilder = {
      url = "github:astro/nix-openwrt-imagebuilder";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    secrets = {
      url = "git+ssh://git@github.com/tomaskala/infra-secrets";

      inputs = {
        nixpkgs.follows = "nixpkgs";
        agenix.follows = "agenix";
      };
    };
  };

  outputs = { nixpkgs, nixpkgs-unstable, nixos-hardware, vps-admin-os
    , catppuccin, nix-darwin, home-manager, agenix, openwrt-imagebuilder
    , secrets, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];

      commonConfig = {
        nixpkgs.overlays = [
          (final: prev: {
            unstable = nixpkgs-unstable.legacyPackages.${prev.system};
            infra = import ./infra { inherit (final.pkgs) lib; };
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
          system = "x86_64-linux";

          modules = [
            commonConfig
            { system.stateVersion = "23.05"; }
            ./machines/whitelodge/configuration.nix
            agenix.nixosModules.default
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.root = import ./machines/whitelodge/root.nix;
              };
            }
            vps-admin-os.nixosConfigurations.container
          ];

          specialArgs = { inherit secrets; };
        };

        bob = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";

          modules = [
            commonConfig
            { system.stateVersion = "23.05"; }
            ./machines/bob/configuration.nix
            agenix.nixosModules.default
            home-manager.nixosModules.home-manager
            nixos-hardware.nixosModules.raspberry-pi-4
          ];

          specialArgs = { inherit secrets; };
        };

        cooper = let system = "x86_64-linux";
        in nixpkgs.lib.nixosSystem {
          inherit system;
          pkgs = forOneSystem (pkgs: pkgs) system;
          modules = [
            ./machines/cooper/configuration.nix
            commonConfig
            nixos-hardware.nixosModules.lenovo-thinkpad-t14-amd-gen2
            agenix.nixosModules.default
            home-manager.nixosModules.default
            { home-manager.useGlobalPkgs = true; }
          ];
        };
      };

      darwinConfigurations = {
        gordon = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";

          modules = [
            commonConfig
            { system.stateVersion = 4; }
            ./machines/gordon/configuration.nix
            agenix.darwinModules.default
            home-manager.darwinModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.tomas = import ./machines/gordon/tomas.nix;
              };
            }
          ];

          specialArgs = { inherit secrets; };
        };
      };

      homeConfigurations = {
        "tomas@blacklodge" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;

          modules = [
            commonConfig
            catppuccin.homeManagerModules.catppuccin
            agenix.homeManagerModules.default
            ./machines/blacklodge/tomas.nix
          ];

          extraSpecialArgs = { inherit secrets; };
        };
      };

      infra.x86_64-linux.audrey = import ./machines/audrey {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        inherit openwrt-imagebuilder;
      };

      devShells = forAllSystems (pkgs: {
        default = import ./shells/infra.nix { inherit pkgs; };
        work = import ./shells/work.nix { inherit pkgs; };
      });

      formatter = forAllSystems (pkgs: pkgs.nixfmt-classic);

      checks = forAllSystems (pkgs: {
        deadnix = import ./checks/deadnix.nix { inherit pkgs; };
        statix = import ./checks/statix.nix { inherit pkgs; };
        nixfmt = import ./checks/nixfmt.nix { inherit pkgs; };
      });
    };
}
