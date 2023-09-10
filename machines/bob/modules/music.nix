{ config, lib, ... }:

let
  cfg = config.services.music;
  intranetCfg = config.networking.intranet;
  gatewayCfg = intranetCfg.gateways.bob;

  nasAddr = intranetCfg.services.nas.ipv4;

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
    # NFSv4 does not need rpcbind.
    services.rpcbind.enable = lib.mkForce false;

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

    services.navidrome = {
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

    services.caddy = {
      enable = true;

      # Explicitly specify HTTP to disable automatic TLS certificate creation,
      # since this is an internal domain only accessible from private subnets.
      virtualHosts."http://${cfg.domain}" = {
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

    services.unbound = {
      enable = true;
      localDomains.${cfg.domain} = { inherit (gatewayCfg.external) ipv4 ipv6; };
    };
  };
}
