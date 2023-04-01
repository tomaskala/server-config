{ config, pkgs, lib, ... }:

let
  cfg = config.services.yarr;
in {
  options.services.yarr = {
    enable = lib.mkEnableOption "yarr";

    listenPort = lib.mkOption {
      type = lib.types.port;
      description = "Listen on this port";
      example = 8080;
    };

    workingDirectory = lib.mkOption {
      type = lib.types.path;
      description = "Where to store the yarr DB file";
      example = "/var/yarr";
    };
  };

  config.services.yarr = lib.mkIf cfg.enable {
    users.users.rss = {
      isSystemUser = true;
      shell = "${pkgs.coreutils}/bin/false";
    };

    services.nginx.virtualHosts.${config.domains.rss} = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:${cfg.listenPort}";
      };

      extraConfig = ''
        allow ${config.maskedSubnet config.intranet.subnets.internal.ipv4}
        allow ${config.maskedSubnet config.intranet.subnets.internal.ipv6}
        deny all;
      '';
    };

    systemd.services.yarr = rec {
      description = "A simple RSS reader";
      after = [ "network.target" ];
      wants = after;
      wantedBy = [ "multi-user.target" ];
      preStart = ''
        ${pkgs.coreutils}/bin/mkdir -p ${cfg.workingDirectory}
      '';
      serviceConfig = {
        User = "rss";
        Group = "rss";
        Type = "simple";
        ExecStart = ''
          ${pkgs.yarr}/bin/yarr -addr 127.0.0.1:${toString cfg.listenPort} -db ${cfg.workingDirectory}/yarr.db
        '';
        WorkingDirectory = cfg.workingDirectory;
        TimeoutStopSec = 20;
        Restart = "on-failure";

        DevicePolicy = "closed";
        NoNewPrivileges = true;
        PrivateTmp = true;
        PrivateUsers = true;
        ProtectControlGroups = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        # The initial '~' character specifies that this is a deny list.
        SystemCallFilter = [ "~@clock" "@debug" "@module" "@mount" "@obsolete" "@reboot" "@setuid" "@swap" ];
        ReadWritePaths = cfg.workingDirectory;
        PrivateDevices = true;
        ProtectSystem = "strict";
        ProtectHome = true;
      };
    };
  };
}
