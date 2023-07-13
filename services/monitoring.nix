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
      settings = {
        server = {
          inherit domain;
          http_addr = "127.0.0.1";
          http_port = cfg.grafanaPort;
        };

        analytics = {
          reporting_enabled = false;
          feedback_links_enabled = false;
          check_for_updates = false;
          check_for_plugin_updates = false;
        };

        provision = {
          enable = true;
          datasources = [{
            name = "Prometheus";
            type = "prometheus";
            access = "proxy";
            url = "http://127.0.0.1:${builtins.toString cfg.prometheus.port}";
          }];
        };

        database = {
          type = "postgres";
          host = "/run/postgresql";
          name = dbName;
          user = dbUser;
          passwordFile = config.age.secrets.postgresql-grafana-password;
        };

        # TODO
        # "auth.anonymous".enabled = true;
        # "auth.anonymous".org_name = "Main Org.";
        # "auth.anonymous".org_role = "Viewer";

        # TODO: settings.security

        # TODO: https://github.com/Mic92/dotfiles/blob/main/nixos/eve/modules/grafana.nix

        # TODO: settings.{server,paths,smtp,users,security,analytics}
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
          extraFlags = [ "--collector.disable-defaults" ];
          enabledCollectors = [
            "arp"
            "bcache"
            "boottime"
            "conntrack"
            "cpu"
            "cpufreq"
            "diskstats"
            "exec"
            "filefd"
            "filesystem"
            "hwmon"
            "loadavg"
            "meminfo"
            "netclass"
            "netdev"
            "netstat"
            "nfs"
            "powersupplyclass"
            "sockstat"
            "stat"
            "thermal"
            "thermal_zone"
            "udp_queues"
            "vmstat"
          ] ++ lib.optionals
            (builtins.elem "zfs" config.boot.supportedFilesystems) [ "zfs" ];
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
