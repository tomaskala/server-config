{ config, pkgs, ... }:

let
  intranetCfg = config.networking.intranet;
  gatewayCfg = intranetCfg.gateways.whitelodge;

  vpnSubnet = intranetCfg.subnets.vpn;
  maskSubnet = { subnet, mask }: "${subnet}/${builtins.toString mask}";
in {
  imports = [
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

    users.users.tomas = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      passwordFile = config.age.secrets.users-tomas-password.path;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMvN19BcNTeaVAF291lBG0z9ROD6J91XAMyy+0VP6CdL cooper2whitelodge"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGRpAi2U+EW2dhKv/tu2DVJPNZnrqgQway2CSAs38tFl blacklodge2whitelodge"
      ];
    };

    users.groups.git = { };
    users.users.git = {
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

    time.timeZone = "Europe/Prague";

    environment.systemPackages = with pkgs; [
      curl
      git
      htop
      ldns
      rsync
      tmux
      tree
      wireguard-tools
    ];

    programs = {
      vim.defaultEditor = true;
      git.config.init.defaultBranch = "master";
    };

    networking.hostName = "whitelodge";
    networking.dhcpcd.enable = false;

    services = {
      ntp.enable = false;
      timesyncd.enable = true;

      firewall.enable = true;
      monitoring.enable = true;
      overlay-network.enable = true;
      unbound-blocker.enable = true;
      vpn.enable = true;

      monitoring-hub = {
        enable = true;
        domain = "monitoring.home.arpa";
        grafanaPort = 3000;
        prometheusPort = 9090;
      };

      openssh = {
        enable = true;
        listenAddresses = [
          { addr = gatewayCfg.internal.interface.ipv4; }
          { addr = gatewayCfg.internal.interface.ipv6; }
        ];
      };

      rss = {
        enable = true;
        domain = "rss.home.arpa";
        port = 7070;
      };

      unbound = {
        enable = true;
        settings.server = {
          interface = [
            "127.0.0.1"
            "::1"
            gatewayCfg.internal.interface.ipv4
            gatewayCfg.internal.interface.ipv6
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
        acmeEmail = "public+acme@tomaskala.com";
      };
    };
  };
}
