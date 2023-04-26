{ config, pkgs, lib, ... }:

let
  cfg = config.services.unbound-blocker;
in
{
  options.services.unbound-blocker = {
    enable = lib.mkEnableOption "unbound-blocker";

    sources = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "List of URLs each containing a blocklist in hosts format";
      example = lib.literalExpression ''[ "https://adaway.org/hosts.txt" ]'';
    };

    whitelist = lib.mkOption {
      default = [ ];
      type = lib.types.listOf lib.types.str;
      description = "Domains whose resolution will never be blocked";
      example = lib.literalExpression ''[ "signal.org" "s.youtube.com" ]'';
    };
  };

  config.services.unbound-blocker = lib.mkIf cfg.enable {
    systemd.services.unbound-blocker = {
      description = "DNS blocklist filling script";
      serviceConfig = {
        User = config.services.unbound.user;
        Group = config.services.unbound.group;
        Type = "oneshot";
        ExecStart = ''
          ${pkgs.unbound-blocker}/bin/fetch_blocklist ${lib.cli.toGNUCommandLineShell { } {
            sources = pkgs.writeTextFile {
              name = "dns-blocker-sources.txt";
              text = builtins.concatStringsSep "\n" cfg.sources;
            };
            whitelist = pkgs.writeTextFile {
              name = "dns-blocker-whitelist.txt";
              text = builtins.concatStringsSep "\n" cfg.whitelist;
            };
          }}
        '';
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
        PrivateDevices = true;
        ProtectSystem = "strict";
        ProtectHome = true;
      };
    };

    systemd.timers.unbound-blocker = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "Sun *-*-* 05:00:00";
        Unit = "unbound-blocker.service";
      };
    };
  };
}
