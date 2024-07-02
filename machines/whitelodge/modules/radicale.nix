{ config, lib, pkgs, secrets, ... }:

let
  inherit (pkgs) infra;

  cfg = config.infra.radicale;
  intranetCfg = config.infra.intranet;
  deviceCfg = intranetCfg.devices.whitelodge;
  allowedIPs = builtins.map infra.ipSubnet [
    intranetCfg.wireguard.internal.ipv4
    intranetCfg.wireguard.internal.ipv6
  ];
in {
  options.infra.radicale = {
    enable = lib.mkEnableOption "DAV server";

    domain = lib.mkOption {
      type = lib.types.str;
      description = "Domain the DAV server is available on";
      default = "dav.whitelodge.tomaskala.com";
      readOnly = true;
    };

    port = lib.mkOption {
      type = lib.types.port;
      description = "Port the DAV server listens on";
      example = 5232;
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

      radicale-htpasswd = {
        file = "${secrets}/secrets/other/whitelodge/radicale-htpasswd.age";
        mode = "0640";
        owner = "root";
        group = "radicale";
      };
    };

    services.radicale = {
      enable = true;
      settings = {
        server.hosts = [ "localhost:${builtins.toString cfg.port}" ];
        auth = {
          type = "htpasswd";
          htpasswd_filename = config.age.secrets.radicale-htpasswd.path;
          htpasswd_encryption = "plain";
        };
        storage = {
          type = "multifilesystem";
          filesystem_folder = "/var/lib/radicale/collections";
        };
        web.type = "internal";
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

    infra.intranet.wireguard.internal.services.dav = {
      url = cfg.domain;
      inherit (deviceCfg.wireguard.internal) ipv4 ipv6;
    };
  };
}
