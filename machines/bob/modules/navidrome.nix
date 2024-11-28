{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (pkgs) infra;

  cfg = config.infra.navidrome;
  intranetCfg = config.infra.intranet;
  deviceCfg = intranetCfg.devices.bob;
  privateSubnet = deviceCfg.wireguard.isolated.subnet;
  nasAddr = privateSubnet.services.nas.ipv4;
  allowedIPs = builtins.map infra.ipSubnet [
    privateSubnet.ipv4
    privateSubnet.ipv6
    intranetCfg.wireguard.internal.ipv4
    intranetCfg.wireguard.internal.ipv6
    intranetCfg.wireguard.isolated.ipv4
    intranetCfg.wireguard.isolated.ipv6
  ];
in
{
  options.infra.navidrome = {
    enable = lib.mkEnableOption "music";

    domain = lib.mkOption {
      type = lib.types.str;
      description = "Domain music is available on";
      example = "music.home.arpa";
    };

    musicDir = lib.mkOption {
      type = lib.types.path;
      description = "Directory containing the music collection";
      example = "/mnt/Music";
    };
  };

  config = lib.mkIf cfg.enable {
    fileSystems.${cfg.musicDir} = {
      device = "${infra.ipAddress nasAddr}:/volume1/Music";
      fsType = "nfs";
      options = [
        # Use NFSv4.1 (the highest my NAS supports).
        "nfsvers=4.1"
        # Lazily mount the filesystem upon first access.
        "x-systemd.automount"
        "noauto"
        # Disconnect from the NFS server after 1 hour of no access.
        "x-systemd.idle-timeout=3600"
        # Mount as a read-only filesystem.
        "ro"
      ];
    };

    services = {
      # NFSv4 does not need rpcbind.
      rpcbind.enable = lib.mkForce false;

      navidrome = {
        enable = true;
        settings = {
          MusicFolder = cfg.musicDir;
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

      caddy = {
        enable = true;

        virtualHosts.${cfg.domain} = {
          listenAddresses = [
            (infra.ipAddress deviceCfg.external.lan.ipv4)
            "[${infra.ipAddress deviceCfg.external.lan.ipv6}]"

            (infra.ipAddress deviceCfg.wireguard.isolated.ipv4)
            "[${infra.ipAddress deviceCfg.wireguard.isolated.ipv6}]"
          ];

          extraConfig = ''
            tls internal

            encode {
              zstd
              gzip 5
            }

            @internal {
              remote_ip ${builtins.toString allowedIPs}
            }

            handle @internal {
              reverse_proxy :${builtins.toString config.services.navidrome.settings.Port}
            }

            respond "Access denied" 403 {
              close
            }
          '';
        };
      };
    };

    infra.intranet.subnets.l-internal.services.music = {
      url = cfg.domain;
      inherit (deviceCfg.external.lan) ipv4 ipv6;
    };
  };
}
