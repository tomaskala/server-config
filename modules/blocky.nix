{ config, lib, pkgs, secrets, ... }:

let
  inherit (pkgs) util;

  cfg = config.infra.blocky;

  dbName = "blocky";
  grafanaDbUser = "${dbName}_grafana";
in {
  options.infra.blocky = {
    enable = lib.mkEnableOption "blocky";

    listenAddresses = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          addr = lib.mkOption {
            type = lib.types.str;
            description = "Listen address";
            example = "127.0.0.1";
          };

          port = lib.mkOption {
            type = lib.types.port;
            description = "Listen port";
            example = 53;
          };
        };
      });
      description = "List of addresses and ports to listen on";
    };

    metrics = lib.mkOption {
      type = lib.types.submodule {
        options = {
          addr = lib.mkOption {
            type = lib.types.str;
            description = "Address to serve HTTP used for Prometheus metrics";
            example = "127.0.0.1";
          };

          port = lib.mkOption {
            type = lib.types.port;
            description = "Port to serve HTTP used for Prometheus metrics";
            example = 4000;
          };
        };
      };
      description = "Prometheus metrics configuration";
    };

    localDomains = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          ipv4 = lib.mkOption {
            type = util.types.ipv4Address;
            description = "IPv4 address the domain resolves to";
          };

          ipv6 = lib.mkOption {
            type = util.types.ipv6Address;
            description = "IPv6 address the domain resolves to";
          };
        };
      });
      description = "Locally-resolvable domains and their addresses";
      default = { };
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      services = {
        blocky = {
          enable = true;

          settings = {
            ports = {
              dns = builtins.map
                ({ addr, port }: "${addr}:${builtins.toString port}")
                cfg.listenAddresses;

              http =
                "${cfg.metrics.addr}:${builtins.toString cfg.metrics.port}";
            };

            prometheus.enable = true;

            upstreams.groups = {
              default = [
                "tcp-tls:9.9.9.9:853#dns.quad9.net"
                "tcp-tls:149.112.112.112:853#dns.quad9.net"
                "tcp-tls:[2620:fe::fe]:853#dns.quad9.net"
                "tcp-tls:[2620:fe::9]:853#dns.quad9.net"
              ];
            };

            blocking = {
              denylists.default = [
                "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/wildcard/pro.txt"
                "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/wildcard/fake.txt"
              ];

              allowlists.default = [''
                clients4.google.com
                clients2.google.com
                s.youtube.com
                video-stats.l.google.com
                www.googleapis.com
                youtubei.googleapis.com
                oauthaccountmanager.googleapis.com
                android.clients.google.com
                reminders-pa.googleapis.com
                firestore.googleapis.com
                gstaticadssl.l.google.com
                googleapis.l.google.com
                dl.google.com
                redirector.gvt1.com
                connectivitycheck.android.com
                android.clients.google.com
                clients3.google.com
                connectivitycheck.gstatic.com
                itunes.apple.com
                s.mzstatic.com
                appleid.apple.com
                gsp-ssl.ls.apple.com
                gsp-ssl.ls-apple.com.akadns.net
                captive.apple.com
                gsp1.apple.com
                www.apple.com
                www.appleiphonecell.com
                tracking-protection.cdn.mozilla.net
                styles.redditmedia.com
                www.redditstatic.com
                reddit.map.fastly.net
                www.redditmedia.com
                reddit-uploaded-media.s3-accelerate.amazonaws.com
                ud-chat.signal.org
                chat.signal.org
                storage.signal.org
                signal.org
                www.signal.org
                updates2.signal.org
                textsecure-service-whispersystems.org
                giphy-proxy-production.whispersystems.org
                cdn.signal.org
                whispersystems-textsecure-attachments.s3-accelerate.amazonaws.com
                d83eunklitikj.cloudfront.net
                souqcdn.com
                cms.souqcdn.com
                api.directory.signal.org
                contentproxy.signal.org
                turn1.whispersystems.org
              ''];

              clientGroupsBlock = { default = [ "default" ]; };
            };

            customDNS = {
              filterUnmappedTypes = true;
              mapping = builtins.mapAttrs (_:
                { ipv4, ipv6 }:
                "${util.ipAddress ipv4},${util.ipAddress ipv6}")
                cfg.localDomains;
            };
          };
        };
      };
    }
    # Do not enable postgres here; we only want to attach to an already running
    # instance, since not all machines running blocky should run postgres.
    (lib.mkIf config.services.postgresql.enable {
      age.secrets = {
        blocky-grafana-postgresql-grafana = {
          file =
            "${secrets}/secrets/other/whitelodge/blocky-grafana-postgresql.age";
          mode = "0640";
          owner = "root";
          group = "grafana";
        };

        blocky-grafana-postgresql-postgresql = {
          file =
            "${secrets}/secrets/other/whitelodge/blocky-grafana-postgresql.age";
          mode = "0640";
          owner = "root";
          group = "postgres";
        };
      };

      services = {
        blocky = {
          settings.queryLog = {
            type = "postgresql";
            target = "postgresql://${dbName}@/${dbName}?host=/run/postgresql";
          };
        };

        postgresql = {
          ensureDatabases = [ dbName ];
          ensureUsers = [
            {
              name = dbName;
              ensureDBOwnership = true;
            }
            { name = grafanaDbUser; }
          ];
        };

        grafana = {
          # Allow scripts in text panels. Necessary for the "Disable blocking"
          # button to work.
          settings.panels.disable_sanitize_html = true;

          provision.datasources.settings.datasources = [{
            name = "PostgreSQL";
            type = "postgres";
            host = "/run/postgresql";
            database = dbName;
            user = grafanaDbUser;
            jsonData.sslmode = "disable";
            secureJsonData.password =
              "$__file{${config.age.secrets.blocky-grafana-postgresql-grafana.path}}";
          }];
        };
      };

      systemd.services.postgresql.postStart = lib.mkAfter ''
        $PSQL -tA <<'EOF'
          DO $$
          DECLARE password TEXT;
          BEGIN
            password := trim(both from replace(pg_read_file('${config.age.secrets.blocky-grafana-postgresql-postgresql.path}'), E'\n', '''));
            EXECUTE format('ALTER ROLE ${grafanaDbUser} WITH PASSWORD '''%s''';', password);
          END $$;
        EOF

        $PSQL -d ${dbName} -tAc 'GRANT USAGE ON SCHEMA public TO ${grafanaDbUser};'
        $PSQL -d ${dbName} -tAc 'GRANT SELECT ON public.log_entries TO ${grafanaDbUser};'
      '';
    })
  ]);
}
