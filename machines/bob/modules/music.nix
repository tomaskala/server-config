{ config, lib, ... }:

let
  cfg = config.services.music;
  intranetCfg = config.networking.intranet;
  gatewayCfg = intranetCfg.gateways.bob;

  nasAddr = intranetCfg.subnets.home-private.services.nas.ipv4;

  vpnSubnet = intranetCfg.subnets.vpn;
  privateSubnet = intranetCfg.subnets.home-private;
  maskSubnet = { subnet, mask }: "${subnet}/${builtins.toString mask}";
in {
  options.services.music = {
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
      device = "${nasAddr}:/volume1/Music";
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
            gatewayCfg.external.ipv4
            "[${gatewayCfg.external.ipv6}]"

            gatewayCfg.internal.interface.ipv4
            "[${gatewayCfg.internal.interface.ipv6}]"
          ];

          extraConfig = ''
            tls internal

            encode {
              zstd
              gzip 5
            }

            @internal {
              remote_ip ${maskSubnet privateSubnet.ipv4} ${
                maskSubnet privateSubnet.ipv6
              } ${maskSubnet vpnSubnet.ipv4} ${maskSubnet vpnSubnet.ipv6}
            }

            handle @internal {
              reverse_proxy :${
                builtins.toString config.services.navidrome.settings.Port
              }
            }

            respond "Access denied" 403 {
              close
            }
          '';
        };
      };
    };

    networking.intranet.subnets.home-private.services.music = {
      url = cfg.domain;
      inherit (gatewayCfg.external) ipv4 ipv6;
    };
  };
}
