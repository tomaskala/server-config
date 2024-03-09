{ config, lib, pkgs, util, ... }:

let
  intranetCfg = config.networking.intranet;
  deviceCfg = intranetCfg.devices.bob;
in {
  imports = [
    ./hardware-configuration.nix
    ./modules/firewall.nix
    ./modules/music.nix
    ./modules/network.nix
    ./modules/vpn.nix
    ./secrets-management.nix
    ../../intranet
    ../../modules/openssh.nix
    ../../modules/unbound-blocker.nix
    ../../modules/unbound.nix
  ];

  config = {
    boot.loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };

    nix = {
      gc = {
        automatic = true;
        dates = "weekly";
      };

      settings = {
        auto-optimise-store = true;
        experimental-features = [ "nix-command" "flakes" ];
      };
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
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF9wbboIeutdnZFbYT5zwJNBf4fJy9njfEMwxOnJKh4z blacklodge2bob"
          ];
        };
      };
    };

    time.timeZone = "Europe/Prague";

    environment.systemPackages = with pkgs; [
      curl
      git
      htop
      ldns
      libraspberrypi
      raspberrypi-eeprom
      rsync
      tmux
      tree
      wireguard-tools
    ];

    programs.vim.defaultEditor = true;

    networking.hostName = "bob";

    services = {
      ntp.enable = false;
      timesyncd.enable = true;

      firewall.enable = true;
      openssh.enable = true;
      unbound-blocker.enable = true;
      vpn.enable = true;

      prometheus.exporters = {
        node = {
          enable = true;
          openFirewall = false;
          listenAddress = util.ipAddress deviceCfg.wireguard.isolated.ipv4;
          port = 9100;
        };
      };

      music = {
        enable = true;
        domain = "music.l.home.arpa";
        musicDir = "/mnt/Music";
      };

      unbound = {
        enable = true;

        settings.server = {
          interface = [
            "127.0.0.1"
            "::1"
            (util.ipAddress deviceCfg.external.lan.ipv4)
            (util.ipAddress deviceCfg.external.lan.ipv6)
          ];
          access-control = [
            "127.0.0.1/8 allow"
            "::1/128 allow"
            "${util.ipSubnet deviceCfg.wireguard.isolated.subnet.ipv4} allow"
            "${util.ipSubnet deviceCfg.wireguard.isolated.subnet.ipv6} allow"
          ];
        };

        localDomains = let
          lServices =
            builtins.attrValues intranetCfg.subnets.l-internal.services;

          urlsToIPs = builtins.map ({ url, ipv4, ipv6 }:
            lib.nameValuePair url {
              ipv4 = util.ipAddress ipv4;
              ipv6 = util.ipAddress ipv6;
            }) lServices;
        in builtins.listToAttrs urlsToIPs;
      };
    };
  };
}
