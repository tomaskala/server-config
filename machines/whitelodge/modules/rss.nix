{ config, lib, ... }:

let
  cfg = config.services.rss;
  intranetCfg = config.networking.intranet;
  peerCfg = intranetCfg.peers.whitelodge;

  vpnSubnet = intranetCfg.subnets.vpn;
  maskSubnet = { subnet, mask }: "${subnet}/${builtins.toString mask}";
in {
  options.services.rss = {
    enable = lib.mkEnableOption "rss";

    domain = lib.mkOption {
      type = lib.types.str;
      description = "Domain RSS is available on";
      example = "rss.home.arpa";
    };

    port = lib.mkOption {
      type = lib.types.port;
      description = "Port RSS listens on";
      example = 7070;
    };
  };

  config = lib.mkIf cfg.enable {
    services.miniflux = {
      enable = true;
      adminCredentialsFile = config.age.secrets.miniflux-admin-credentials.path;
      config = {
        POLLING_FREQUENCY = "1440";
        LISTEN_ADDR = "127.0.0.1:${builtins.toString cfg.port}";
        BASE_URL = "http://${cfg.domain}";
        CLEANUP_ARCHIVE_UNREAD_DAYS = "-1";
      };
    };

    services.caddy = {
      enable = true;

      # Explicitly specify HTTP to disable automatic TLS certificate creation,
      # since this is an internal domain only accessible from the VPN.
      virtualHosts."http://${cfg.domain}" = {
        extraConfig = ''
          reverse_proxy :${builtins.toString cfg.port}

          @blocked not remote_ip ${maskSubnet vpnSubnet.ipv4} ${
            maskSubnet vpnSubnet.ipv6
          }
          respond @blocked "Forbidden" 403
        '';
      };
    };

    services.unbound = {
      enable = true;
      localDomains.${cfg.domain} = {
        inherit (peerCfg.internal.interface) ipv4 ipv6;
      };
    };
  };
}
