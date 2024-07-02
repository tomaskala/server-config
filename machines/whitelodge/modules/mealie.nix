{ config, lib, pkgs, secrets, ... }:

let
  inherit (pkgs) util;

  cfg = config.infra.mealie;
  intranetCfg = config.infra.intranet;
  deviceCfg = intranetCfg.devices.whitelodge;
  allowedIPs = builtins.map util.ipSubnet [
    intranetCfg.wireguard.internal.ipv4
    intranetCfg.wireguard.internal.ipv6
  ];

  dbName = "mealie";
in {
  options.infra.mealie = {
    enable = lib.mkEnableOption "mealie";

    domain = lib.mkOption {
      type = lib.types.str;
      description = "Domain Mealie is available on";
      default = "mealie.whitelodge.tomaskala.com";
      readOnly = true;
    };

    port = lib.mkOption {
      type = lib.types.port;
      description = "Port Mealie listens on";
      example = 9000;
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

    services = {
      mealie = {
        enable = true;
        package = pkgs.unstable.mealie;
        inherit (cfg) port;

        listenAddress = "127.0.0.1";

        settings = {
          ALLOW_SIGNUP = "false";
          DB_ENGINE = "postgres";
          POSTGRES_URL_OVERRIDE =
            "postgresql://${dbName}:@/${dbName}?host=/run/postgresql";
        };
      };

      postgresql = {
        enable = true;
        ensureDatabases = [ dbName ];
        ensureUsers = [{
          name = dbName;
          ensureDBOwnership = true;
        }];
      };

      caddy = {
        enable = true;

        virtualHosts.${cfg.domain} = {
          listenAddresses = [
            (util.ipAddress deviceCfg.wireguard.internal.ipv4)
            "[${util.ipAddress deviceCfg.wireguard.internal.ipv6}]"
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
    };

    infra.intranet.wireguard.internal.services.mealie = {
      url = cfg.domain;
      inherit (deviceCfg.wireguard.internal) ipv4 ipv6;
    };
  };
}
