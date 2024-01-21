{ config, lib, ... }:

let
  cfg = config.services.rss;
  intranetCfg = config.networking.intranet;
  gatewayCfg = intranetCfg.gateways.whitelodge;

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
        BASE_URL = "https://${cfg.domain}";
        CLEANUP_ARCHIVE_UNREAD_DAYS = "-1";
      };
    };

    services.caddy = {
      enable = true;

      virtualHosts.${cfg.domain} = {
        listenAddresses = [
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
            remote_ip ${maskSubnet vpnSubnet.ipv4} ${maskSubnet vpnSubnet.ipv6}
          }

          handle @internal {
            reverse_proxy :${builtins.toString cfg.port}
          }

          respond "Access denied" 403 {
            close
          }
        '';
      };
    };

    networking.intranet.subnets.vpn.services.rss = {
      url = cfg.domain;
      inherit (gatewayCfg.internal.interface) ipv4 ipv6;
    };
  };
}
