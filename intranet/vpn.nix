{ config, lib, util, ... }:

{
  options.networking.intranet.vpn = lib.mkOption {
    type = lib.types.attrsOf util.types.vpnSubnet;
    description = "VPN subnets in the intranet";
  };

  config.networking.intranet.vpn = {
    internal = {
      ipv4 = {
        inherit (config.networking.intranet.ranges.vpn-internal)
          location subnet;
        mask = 24;
      };

      ipv6 = {
        inherit (config.networking.intranet.ranges.vpn-internal)
          location subnet;
        mask = 64;
      };

      devices = [
        {
          interface =
            config.networking.intranet.devices.blacklodge.wireguard.internal;
          presharedKeyFile = config.age.secrets.wg-blacklodge2whitelodge.path;
        }
        {
          interface =
            config.networking.intranet.devices.cooper.wireguard.internal;
          presharedKeyFile = config.age.secrets.wg-cooper2whitelodge.path;
        }
        {
          interface =
            config.networking.intranet.devices.tomas-phone.wireguard.internal;
          presharedKeyFile = config.age.secrets.wg-tomas-phone2whitelodge.path;
        }
      ];
    };

    isolated = {
      ipv4 = {
        inherit (config.networking.intranet.ranges.vpn-isolated)
          location subnet;
        mask = 24;
      };

      ipv6 = {
        inherit (config.networking.intranet.ranges.vpn-isolated)
          location subnet;
        mask = 64;
      };

      devices = [{
        interface = config.networking.intranet.devices.bob.wireguard.isolated;
        presharedKeyFile = config.age.secrets.wg-bob2whitelodge.path;
      }];
    };

    passthru = {
      ipv4 = {
        inherit (config.networking.intranet.ranges.vpn-passthru)
          location subnet;
        mask = 24;
      };

      ipv6 = {
        inherit (config.networking.intranet.ranges.vpn-passthru)
          location subnet;
        mask = 64;
      };

      devices = [{
        interface =
          config.networking.intranet.devices.audrey.wireguard.passthru;
        presharedKeyFile = config.age.secrets.wg-audrey2whitelodge.path;
      }];
    };
  };
}
