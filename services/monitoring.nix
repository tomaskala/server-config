{ config, lib, ... }:

let
  cfg = config.services.monitoring;

  inherit (config.networking) hostName;
  domain = "${hostName}.home.arpa";

  dbName = "grafana";
  dbUser = "grafana";

  intranetCfg = config.networking.intranet;
  vpnSubnet = intranetCfg.subnets.vpn;
  maskSubnet = { subnet, mask }: "${subnet}/${builtins.toString mask}";
in {
  options.services.monitoring = {
    enable = lib.mkEnableOption "monitoring";

    grafanaPort = lib.mkOption {
      type = lib.types.port;
      description = "Port that Grafana listens on";
      example = 3000;
      default = 3000;
    };

    prometheus = lib.mkOption {
      type = lib.types.submodule {
        options = {
          port = lib.mkOption {
            type = lib.types.port;
            description = "Port that Prometheus listens on";
            example = 9090;
            default = 9090;
          };

          nodeExporterPort = lib.mkOption {
            type = lib.types.port;
            description = "Port that Prometheus Node exporter listens on";
            example = 9100;
            default = 9100;
          };
        };
      };
      description = "Prometheus configuration";
      default = { };
    };
  };

  config = lib.mkIf cfg.enable {
    services.grafana = {
      enable = true;

      provision = {
        enable = true;

        datasources.settings.datasources = [{
          name = "Prometheus";
          type = "prometheus";
          access = "proxy";
          url = "http://127.0.0.1:${builtins.toString cfg.prometheus.port}";
        }];

        dashboards.settings.providers = [{
          name = "Grafana dashboards";
          # It's useless to check the dashboard directory for updates because
          # it lives on a readonly file system, but grafana doesn't allow to
          # disable the checking completely. Even setting this value to zero
          # doesn't help, because in that case, it gets silently converted
          # to 10 anyway:
          # https://github.com/grafana/grafana/blob/bc2813ef0661eb0fd317a7ed2dff4db056cbe7e6/pkg/services/provisioning/dashboards/config_reader.go#L107-L109
          # Setting to a large value instead to not check too often.
          updateIntervalSeconds = 60 * 60 * 24;
          options.path = "${./grafana-dashboards}";
        }];
      };

      settings = {
        server = {
          inherit domain;
          http_addr = "127.0.0.1";
          http_port = cfg.grafanaPort;
          enable_gzip = true;
        };

        analytics = {
          reporting_enabled = false;
          feedback_links_enabled = false;
          check_for_updates = false;
          check_for_plugin_updates = false;
        };

        database = {
          type = "postgres";
          host = "/run/postgresql";
          name = dbName;
          user = dbUser;
          passwordFile = config.age.secrets.postgresql-grafana-password.path;
        };

        security = {
          disable_gravatar = true;
          admin_password =
            "$__file{${config.age.secrets.grafana-admin-password.path}}";
        };
      };
    };

    services.postgresql = {
      ensureDatabases = [ dbName ];
      ensureUsers = [{
        name = dbUser;
        ensurePermissions = { "DATABASE ${dbName}" = "ALL PRIVILEGES"; };
      }];
    };

    services.prometheus = {
      enable = true;
      listenAddress = "127.0.0.1";
      inherit (cfg.prometheus) port;

      scrapeConfigs = [{
        job_name = hostName;
        static_configs = [{
          targets = [
            "127.0.0.1:${builtins.toString cfg.prometheus.nodeExporterPort}"
          ];
        }];
      }];

      exporters = {
        node = {
          enable = true;
          listenAddress = "127.0.0.1";
          port = cfg.prometheus.nodeExporterPort;
          openFirewall = false;
        };
      };
    };

    services.caddy = {
      virtualHosts."http://${domain}" = {
        extraConfig = ''
          reverse_proxy :${
            builtins.toString config.services.grafana.settings.server.http_port
          }

          @blocked not remote_ip ${maskSubnet vpnSubnet.ipv4} ${
            maskSubnet vpnSubnet.ipv6
          }
          respond @blocked "Forbidden" 403
        '';
      };
    };
  };
}
