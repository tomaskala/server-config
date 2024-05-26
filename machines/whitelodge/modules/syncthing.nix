{ config, lib, secrets, util, ... }:

let
  cfg = config.infra.syncthing;
  intranetCfg = config.infra.intranet;
  deviceCfg = intranetCfg.devices.whitelodge;
  allowedIPs = builtins.map util.ipSubnet [
    intranetCfg.wireguard.internal.ipv4
    intranetCfg.wireguard.internal.ipv6
  ];

  mkDevice = _:
    { syncthing, ... }: {
      inherit (syncthing) id introducer;
      address = [
        "tcp4://${util.ipAddress syncthing.ipv4}"
        "tcp6://[${util.ipAddress syncthing.ipv6}]"
      ];
    };

  mkFolderPath = name: "${config.services.syncthing.dataDir}/${name}";
in {
  options.infra.syncthing = {
    enable = lib.mkEnableOption "syncthing";

    domain = lib.mkOption {
      type = lib.types.str;
      description = "Domain Syncthing is available on";
      default = "syncthing.whitelodge.tomaskala.com";
      readOnly = true;
    };

    ports = lib.mkOption {
      type = lib.types.submodule {
        options = {
          web = lib.mkOption {
            type = lib.types.port;
            description = "Port the web interface listens on";
            example = 8384;
          };

          listen = lib.mkOption {
            type = lib.types.port;
            description = "Port Syncthing listens on";
            example = 22000;
          };
        };
      };
    };

    acmeEmail = lib.mkOption {
      type = lib.types.str;
      description = "ACME account email address";
      example = "acme@example.com";
    };
  };

  config = lib.mkIf cfg.enable {
    services.syncthing = {
      enable = true;
      relay.enable = false;
      openDefaultPorts = false;
      overrideDevices = true;
      overrideFolders = true;

      settings = {
        gui = {
          enabled = true;
          tls = true;
          theme = "dark";
        };

        options = {
          listenAddress = [
            "tcp4://${util.ipAddress deviceCfg.wireguard.internal.ipv4}:${
              builtins.toString cfg.ports.listen
            }"
            "tcp6://[${util.ipAddress deviceCfg.wireguard.internal.ipv6}]:${
              builtins.toString cfg.ports.listen
            }"
          ];
          globalAnnounceEnabled = false;
          localAnnounceEnabled = false;
          relaysEnabled = false;
          natEnabled = false;
          urAccepted = -1;
          stunKeepaliveStartS = 0;
          announceLANAddresses = false;
        };

        folders = {
          documents = {
            id = ""; # TODO
            path = mkFolderPath "documents";

            # The folder is in “receive only” mode – it will not propagate
            # changes to other devices.
            type = "receiveonly";
            fsWatcherEnabled = false;

            devices = lib.mapAttrsToList (_: { syncthing, ... }: syncthing.id)
              (lib.filterAttrs (_: { syncthing, ... }: syncthing != null)
                intranetCfg.devices);
          };
        };

        devices = builtins.mapAttrs mkDevice
          (lib.filterAttrs (_: { syncthing, ... }: syncthing != null)
            intranetCfg.devices);
      };

      # TODO: Add domain to cloudflare;
      guiAddress = "127.0.0.1:${builtins.toString cfg.ports.web}";
      # TODO: Store in the secrets repository.
      key = "TODO";
      cert = "TODO";

      extraFlags = [ "--no-default-folder" ];
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
            reverse_proxy :${builtins.toString cfg.ports.web}
          }

          respond "Access denied" 403 {
            close
          }
        '';
      };
    };

    infra.intranet.wireguard.internal.services.syncthing = {
      url = cfg.domain;
      inherit (deviceCfg.wireguard.internal) ipv4 ipv6;
    };
  };
}
