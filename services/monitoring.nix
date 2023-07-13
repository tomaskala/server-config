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
        datasources = [{
          name = "Prometheus";
          type = "prometheus";
          access = "proxy";
          url = "http://127.0.0.1:${builtins.toString cfg.prometheus.port}";
        }];
      };

      settings = {
        server = {
          inherit domain;
          protocol = "socket";
          socket_gid = config.users.groups.${config.services.caddy.group}.gid;
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
          passwordFile = config.age.secrets.postgresql-grafana-password;
        };

        security = {
          disable_gravatar = true;
          admin_password =
            "$__file{${config.age.secrets.grafana-admin-password}}";
        };

        # TODO: Make Prometheus listen on a Unix socket?
        # TODO: Disable postgres localhost altogether, sockets are used both
        # TODO: here as well as at miniflux.
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
          reverse_proxy unix//${config.services.grafana.settings.server.socket}

          @blocked not remote_ip ${maskSubnet vpnSubnet.ipv4} ${
            maskSubnet vpnSubnet.ipv6
          }
          respond @blocked "Forbidden" 403
        '';
      };
    };
  };
}
