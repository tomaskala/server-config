{ config, lib, pkgs, secrets, ... }:

let
  inherit (pkgs) infra;

  cfg = config.infra.miniflux;
  intranetCfg = config.infra.intranet;
  deviceCfg = intranetCfg.devices.whitelodge;
  allowedIPs = builtins.map infra.ipSubnet [
    intranetCfg.wireguard.internal.ipv4
    intranetCfg.wireguard.internal.ipv6
  ];
in {
  options.infra.miniflux = {
    enable = lib.mkEnableOption "rss";

    domain = lib.mkOption {
      type = lib.types.str;
      description = "Domain RSS is available on";
      default = "rss.whitelodge.tomaskala.com";
      readOnly = true;
    };

    port = lib.mkOption {
      type = lib.types.port;
      description = "Port RSS listens on";
      example = 7070;
    };

    acmeEmail = lib.mkOption {
      type = lib.types.str;
      description = "ACME account email address";
      example = "acme@example.com";
    };
  };

  config = lib.mkIf cfg.enable {
    age.secrets = {
      cloudflare-dns-challenge-api-tokens.file =
        "${secrets}/secrets/other/whitelodge/cloudflare-dns-challenge-api-tokens.age";
      miniflux-admin-credentials.file =
        "${secrets}/secrets/other/whitelodge/miniflux-whitelodge.age";
    };

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

    security.acme = {
      acceptTerms = true;

      certs.${cfg.domain} = {
        dnsProvider = "cloudflare";
        email = cfg.acmeEmail;
        environmentFile =
          config.age.secrets.cloudflare-dns-challenge-api-tokens.path;
      };
    };

    services.caddy = {
      enable = true;

      virtualHosts.${cfg.domain} = {
        listenAddresses = [
          (infra.ipAddress deviceCfg.wireguard.internal.ipv4)
          "[${infra.ipAddress deviceCfg.wireguard.internal.ipv6}]"
        ];

        useACMEHost = cfg.domain;

        extraConfig = ''
          encode {
            zstd
            gzip 5
          }

          @internal {
            remote_ip ${builtins.toString allowedIPs}
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

    infra.intranet.wireguard.internal.services.rss = {
      url = cfg.domain;
      inherit (deviceCfg.wireguard.internal) ipv4 ipv6;
    };
  };
}
