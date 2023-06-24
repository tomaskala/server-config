{ config, pkgs, ... }:

let
  nasAddr = intranetCfg.localDomains."nas.home.arpa".ipv4;
  musicDir = "/mnt/Music";

  intranetCfg = config.networking.intranet;
  peerCfg = intranetCfg.peers.bob;
  vpnInterface = peerCfg.internal.interface.name;

  vpnSubnet = intranetCfg.subnets.vpn;
  privateSubnet = intranetCfg.subnets.home-private;
  maskSubnet = { subnet, mask }: "${subnet}/${builtins.toString mask}";
in {
  imports = [
    ./hardware-configuration.nix
    ./secrets-management.nix
    ../intranet.nix
    ../../services/openssh.nix
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

    users.users.tomas = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      passwordFile = config.age.secrets."users-tomas-password-bob".path;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF9wbboIeutdnZFbYT5zwJNBf4fJy9njfEMwxOnJKh4z blacklodge2bob"
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

    programs.vim.defaultEditor = true;

    networking.hostName = "bob";
    networking.firewall.enable = false;
    networking.nftables = {
      enable = true;
      ruleset = import ./nftables-ruleset.nix { inherit config; };
      checkRuleset = true;
    };

    systemd.network = {
      enable = true;

      netdevs."90-${vpnInterface}" = {
        netdevConfig = {
          Name = vpnInterface;
          Kind = "wireguard";
        };

        wireguardConfig = { PrivateKeyFile = config.age.secrets.wg-pk.path; };

        wireguardPeers = [{
          wireguardPeerConfig = {
            # whitelodge
            PublicKey = intranetCfg.peers.whitelodge.publicKey;
            PresharedKeyFile = config.age.secrets.wg-bob2whitelodge.path;
            AllowedIPs = [
              (maskSubnet intranetCfg.peers.whitelodge.internal.interface.ipv4)
              (maskSubnet intranetCfg.peers.whitelodge.internal.interface.ipv6)
            ];
            Endpoint = "${intranetCfg.peers.whitelodge.external.ipv4}:${
                builtins.toString intranetCfg.peers.whitelodge.port
              }";
            PersistentKeepalive = 25;
          };
        }];
      };

      networks."90-${vpnInterface}" = {
        matchConfig.Name = vpnInterface;

        # Enable IP forwarding (system-wide).
        networkConfig.IPForward = true;

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

    fileSystems.${musicDir} = {
      device = "${nasAddr}:/volume1/Music";
      fsType = "nfs";
      options = [
        # Lazily mount the filesystem upon first access.
        "x-systemd.automount"
        "noauto"
        # Disconnect from the NFS server after 1 hour of no access.
        "x-systemd.idle-timeout=3600"
        # Mount as a read-only filesystem.
        "ro"
      ];
    };

    services.openssh = {
      enable = true;
      listenAddresses = [
        { addr = peerCfg.internal.interface.ipv4; }
        { addr = peerCfg.internal.interface.ipv6; }
        { addr = peerCfg.external.ipv4; }
        { addr = peerCfg.external.ipv6; }
      ];
    };

    services.navidrome = {
      enable = true;
      settings = {
        MusicFolder = musicDir;
        LogLevel = "warn";
        Address = "127.0.0.1";
        AutoImportPlaylists = false;
        EnableCoverAnimation = false;
        EnableExternalServices = false;
        EnableFavourites = false;
        EnableGravatar = false;
        EnableStarRating = false;
        EnableTranscodingConfig = false;
        "LastFM.Enabled" = false;
        "ListenBrainz.Enabled" = false;
        "Prometheus.Enabled" = false;
        ScanSchedule = "@every 24h";
      };
    };

    services.caddy = {
      enable = true;
      # Explicitly specify HTTP to disable automatic TLS certificate creation,
      # since this is an internal domain only accessible from private subnets.
      virtualHosts."http://music.home.arpa" = {
        extraConfig = ''
          reverse_proxy :${
            builtins.toString config.services.navidrome.settings.Port
          }

          @blocked not remote_ip ${maskSubnet privateSubnet.ipv4} ${
            maskSubnet privateSubnet.ipv6
          } ${maskSubnet vpnSubnet.ipv4} ${maskSubnet vpnSubnet.ipv6}
          respond @blocked "Forbidden" 403
        '';
      };
    };
  };
}
