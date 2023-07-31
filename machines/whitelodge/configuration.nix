{ config, pkgs, ... }:

let
  publicDomain = "tomaskala.com";
  publicDomainWebroot = "/var/www/${publicDomain}";
  acmeEmail = "public+acme@${publicDomain}";

  intranetCfg = config.networking.intranet;
  peerCfg = intranetCfg.peers.whitelodge;
  vpnInterface = peerCfg.internal.interface.name;

  vpnSubnet = intranetCfg.subnets.vpn;
  maskSubnet = { subnet, mask }: "${subnet}/${builtins.toString mask}";
in {
  imports = [
    ./modules/rss.nix
    ./modules/monitoring-hub.nix
    ./modules/overlay-network.nix
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
      passwordFile = config.age.secrets."users-tomas-password-whitelodge".path;
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
    services.ntp.enable = false;
    services.timesyncd.enable = true;

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
    networking.firewall.enable = false;
    networking.nftables = {
      enable = true;
      ruleset = import ./modules/nftables-ruleset.nix { inherit config; };

      # Ruleset checking reports errors with chains defined on top of the
      # ingress hook. This hook must be interface-specific, and the ruleset
      # check always fails as it runs in a sandbox. A solution is to rename
      # all occurrences of the WAN interface to the loopback interface, which
      # is available even inside the sandbox.
      # Source: https://github.com/NixOS/nixpkgs/pull/223283/files.
      checkRuleset = true;
      preCheckRuleset = ''
        ${pkgs.gnused}/bin/sed -i 's/${peerCfg.external.name}/lo/g' ruleset.conf
      '';
    };

    systemd.network = {
      enable = true;

      netdevs."90-${vpnInterface}" = {
        netdevConfig = {
          Name = vpnInterface;
          Kind = "wireguard";
        };

        wireguardConfig = {
          PrivateKeyFile = config.age.secrets.wg-pk.path;
          ListenPort = peerCfg.internal.port;
        };

        wireguardPeers = [
          {
            wireguardPeerConfig = {
              # cooper
              PublicKey = "0F/gm1t4hV19N/U/GyB2laclS3CPfGDR2aA3f53EGXk=";
              PresharedKeyFile = config.age.secrets.wg-cooper2whitelodge.path;
              AllowedIPs = [ "10.100.100.1/32" "fd25:6f6:a9f:1100::1/128" ];
            };
          }
          {
            wireguardPeerConfig = {
              # tomas-phone
              PublicKey = "DTJ3VeQGDehQBkYiteIpxtatvgqy2Ux/KjQEmXaEoEQ=";
              PresharedKeyFile =
                config.age.secrets.wg-tomas-phone2whitelodge.path;
              AllowedIPs = [ "10.100.100.2/32" "fd25:6f6:a9f:1100::2/128" ];
            };
          }
          {
            wireguardPeerConfig = {
              # blacklodge
              PublicKey = "b1vNeOy10kbXfldKbaAd5xa2cndgzOE8kQ63HoWXIko=";
              PresharedKeyFile =
                config.age.secrets.wg-blacklodge2whitelodge.path;
              AllowedIPs = [ "10.100.100.3/32" "fd25:6f6:a9f:1100::3/128" ];
            };
          }
          {
            wireguardPeerConfig = {
              # martin-windows
              PublicKey = "JoxRQuYsNZqg/e/DHIVnAsDsA86PjyDlIWPIViMrPUQ=";
              PresharedKeyFile =
                config.age.secrets.wg-martin-windows2whitelodge.path;
              AllowedIPs = [ "10.100.104.1/32" "fd25:6f6:a9f:1200::1/128" ];
            };
          }
        ];
      };

      networks."90-${vpnInterface}" = {
        matchConfig.Name = vpnInterface;

        address = [
          "${peerCfg.internal.interface.ipv4}/${
            builtins.toString vpnSubnet.ipv4.mask
          }"
          "${peerCfg.internal.interface.ipv6}/${
            builtins.toString vpnSubnet.ipv6.mask
          }"
        ];
      };
    };

    networking.overlay-network.enable = true;

    services.openssh = {
      enable = true;
      listenAddresses = [
        { addr = peerCfg.internal.interface.ipv4; }
        { addr = peerCfg.internal.interface.ipv6; }
      ];
    };

    services.rss = {
      enable = true;
      domain = "rss.home.arpa";
      port = 7070;
    };

    services.caddy = {
      enable = true;
      email = acmeEmail;

      virtualHosts.${publicDomain} = {
        extraConfig = ''
          root * ${publicDomainWebroot}
          encode gzip
          file_server

          header {
            # Disable FLoC tracking.
            Permissions-Policy interest-cohort=()

            # Enable HSTS.
            Strict-Transport-Security max-age=31536000

            # Disable clients from sniffing the media type.
            X-Content-Type-Options nosniff

            # Clickjacking protection.
            X-Frame-Options DENY

            # Keep referrer data off third parties.
            Referrer-Policy same-origin

            # Content should come from the site's origin (excludes subdomains).
            # Prevent the framing of this site by other sites.
            Content-Security-Policy "default-src 'self'; frame-ancestors 'none'"
          }
        '';
      };
    };

    services.unbound = {
      enable = true;

      settings.server = {
        interface = [
          "127.0.0.1"
          "::1"
          peerCfg.internal.interface.ipv4
          peerCfg.internal.interface.ipv6
        ];
        access-control = [
          "127.0.0.1/8 allow"
          "::1/128 allow"
          "${maskSubnet vpnSubnet.ipv4} allow"
          "${maskSubnet vpnSubnet.ipv6} allow"
        ];
      };

      localDomains = {
        "${publicDomain}" = { inherit (peerCfg.internal.interface) ipv4 ipv6; };
      };
    };

    services.unbound-blocker.enable = true;

    services.monitoring-hub.enable = true;

    services.monitoring.enable = true;
  };
}
