{ config, lib, ... }:

let
  cfg = config.services.dav;
  intranetCfg = config.networking.intranet;
  gatewayCfg = intranetCfg.gateways.whitelodge;

  vpnSubnet = intranetCfg.subnets.vpn;
  maskSubnet = { subnet, mask }: "${subnet}/${builtins.toString mask}";
in {
  options.services.dav = {
    enable = lib.mkEnableOption "DAV server";

    domain = lib.mkOption {
      type = lib.types.str;
      description = "Domain the DAV server is available on";
      example = "dav.home.arpa";
    };

    port = lib.mkOption {
      type = lib.types.port;
      description = "Port the DAV server listens on";
      example = 5232;
    };
  };

  config = lib.mkIf cfg.enable {
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

    services.caddy = {
      enable = true;

      # Explicitly specify HTTP to disable automatic TLS certificate creation,
      # since this is an internal domain only accessible from the VPN.
      virtualHosts."http://${cfg.domain}" = {
        extraConfig = ''
          encode {
            zstd
            gzip 5
          }

          reverse_proxy :${builtins.toString cfg.port}

          @blocked not remote_ip ${maskSubnet vpnSubnet.ipv4} ${
            maskSubnet vpnSubnet.ipv6
          }
          respond @blocked "Forbidden" 403
        '';
      };
    };

    networking.intranet.subnets.vpn.services.dav = {
      url = cfg.domain;
      inherit (gatewayCfg.internal.interface) ipv4 ipv6;
    };
  };
}
