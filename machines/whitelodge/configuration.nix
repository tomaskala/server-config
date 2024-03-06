{ config, pkgs, ... }:

let
  intranetCfg = config.networking.intranet;

  vpnSubnet = intranetCfg.subnets.vpn;
  maskSubnet = { subnet, mask }: "${subnet}/${builtins.toString mask}";

  acmeEmail = "public+acme@tomaskala.com";
in {
  imports = [
    ./modules/dav.nix
    ./modules/firewall.nix
    ./modules/monitoring-hub.nix
    ./modules/overlay-network.nix
    ./modules/rss.nix
    ./modules/vpn.nix
    ./modules/website.nix
    ./secrets-management.nix
    ../intranet.nix
    ../../modules/monitoring.nix
    ../../modules/openssh.nix
    ../../modules/unbound-blocker.nix
    ../../modules/unbound.nix
  ];

  config = {
    nix = {
      gc = {
        automatic = true;
        dates = "weekly";
        # The system is running on ZFS, so we don't need Nix generations.
        options = "--delete-old";
      };

      settings = {
        # Optimise the store after each build (as opposed to nix.optimise.*
        # which sets up a systemd timer to optimise the store periodically).
        auto-optimise-store = true;
        experimental-features = [ "nix-command" "flakes" ];
      };
    };

    system.autoUpgrade = {
      enable = true;
      operation = "switch";
      flake = "github:tomaskala/infra";

      # Run after the automatic flake.lock update configured in Github Actions.
      dates = "Sun *-*-* 03:00:00";

      # The system runs in a container, sharing the Linux kernel with other
      # containers. As such, no kernel upgrades can happen during a system
      # upgrade, and no reboot is necessary. When enabled, this broke the
      # nixos-upgrade service because it attempted to read non-existent
      # files under /run/booted-system.
      allowReboot = false;
    };

    users = {
      mutableUsers = false;

      users = {
        root.hashedPasswordFile = config.age.secrets.users-root-password.path;

        tomas = {
          isNormalUser = true;
          extraGroups = [ "wheel" ];
          hashedPasswordFile = config.age.secrets.users-tomas-password.path;
          openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMvN19BcNTeaVAF291lBG0z9ROD6J91XAMyy+0VP6CdL cooper2whitelodge"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGRpAi2U+EW2dhKv/tu2DVJPNZnrqgQway2CSAs38tFl blacklodge2whitelodge"
          ];
        };

        git = {
          isSystemUser = true;
          createHome = true;
          home = "/home/git";
          shell = "${pkgs.git}/bin/git-shell";
          group = "git";
          openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGbhtSz3s/zgTVWg7d37J9qeKk+u4H+jJhwvj/QXjaIW cooper2whitelodge-git"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIApzsZJs9oocJnP2JnIsSZFmmyWdUm/2IgRHcJgCqFc1 tomas-phone2whitelodge-git"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP3iFrxprV/hToSeHEIo2abt/IcK/M86iqF4mV6S81Rf blacklodge2whitelodge-git"
          ];
        };
      };

      groups.git = { };
    };

    time.timeZone = "Etc/UTC";

    environment = {
      noXlibs = true;
      systemPackages = with pkgs; [
        curl
        git
        htop
        ldns
        rsync
        tmux
        tree
        wireguard-tools
      ];
    };

    programs = {
      vim.defaultEditor = true;
      git.config.init.defaultBranch = "master";
    };

    networking = {
      hostName = "whitelodge";
      useDHCP = false;
    };

    services = {
      ntp.enable = false;
      timesyncd.enable = true;

      firewall.enable = true;
      monitoring.enable = true;
      overlay-network.enable = true;
      unbound-blocker.enable = true;
      vpn.enable = true;

      dav = {
        enable = true;
        port = 5232;
        inherit acmeEmail;
      };

      monitoring-hub = {
        enable = true;
        grafanaPort = 3000;
        prometheusPort = 9090;
        inherit acmeEmail;
      };

      openssh = {
        enable = true;
        listenAddresses = [
          {
            addr = intranetCfg.subnets.vpn-internal.gateway.interface.ipv4;
            port = 22;
          }
          {
            addr = intranetCfg.subnets.vpn-internal.gateway.interface.ipv6;
            port = 22;
          }
        ];
      };

      rss = {
        enable = true;
        port = 7070;
        inherit acmeEmail;
      };

      unbound = {
        enable = true;
        settings.server = {
          interface = [
            # Allow the server itself to use the resolver.
            "127.0.0.1"
            "::1"
            # Allow internal peers to use the resolver. This is to allow
            # resolving internal domain names as well as to use it for
            # domain filtering when accessing the public internet.
            intranetCfg.subnets.vpn-internal.gateway.interface.ipv4
            intranetCfg.subnets.vpn-internal.gateway.interface.ipv6
            # Allow isolated peers to use the resolver. This is to allow
            # resolving internal domain names.
            intranetCfg.subnets.vpn-isolated.gateway.interface.ipv4
            intranetCfg.subnets.vpn-isolated.gateway.interface.ipv6
          ];
          access-control = [
            "127.0.0.1/8 allow"
            "::1/128 allow"
            "${maskSubnet vpnSubnet.ipv4} allow"
            "${maskSubnet vpnSubnet.ipv6} allow"
          ];
        };
      };

      website = {
        enable = true;
        domain = "tomaskala.com";
        webroot = "/var/www/tomaskala.com";
        inherit acmeEmail;
      };
    };
  };
}
