{ config, lib, util, ... }:

{
  options.infra.intranet.wireguard = lib.mkOption {
    type = lib.types.attrsOf util.types.wgSubnet;
    description = "WireGuard subnets in the intranet";
  };

  config = {
    infra.intranet.wireguard = {
      internal = {
        ipv4 = {
          inherit (config.infra.intranet.ranges.wg-internal) location subnet;
          mask = 24;
        };

        ipv6 = {
          inherit (config.infra.intranet.ranges.wg-internal) location subnet;
          mask = 64;
        };

        devices = [
          {
            interface =
              config.infra.intranet.devices.blacklodge.wireguard.internal;
            presharedKeyFile = config.age.secrets.wg-blacklodge2whitelodge.path;
          }
          {
            interface = config.infra.intranet.devices.cooper.wireguard.internal;
            presharedKeyFile = config.age.secrets.wg-cooper2whitelodge.path;
          }
          {
            interface =
              config.infra.intranet.devices.tomas-phone.wireguard.internal;
            presharedKeyFile =
              config.age.secrets.wg-tomas-phone2whitelodge.path;
          }
        ];
      };

      isolated = {
        ipv4 = {
          inherit (config.infra.intranet.ranges.wg-isolated) location subnet;
          mask = 24;
        };

        ipv6 = {
          inherit (config.infra.intranet.ranges.wg-isolated) location subnet;
          mask = 64;
        };

        devices = [{
          interface = config.infra.intranet.devices.bob.wireguard.isolated;
          presharedKeyFile = config.age.secrets.wg-bob2whitelodge.path;
        }];
      };

      passthru = {
        ipv4 = {
          inherit (config.infra.intranet.ranges.wg-passthru) location subnet;
          mask = 24;
        };

        ipv6 = {
          inherit (config.infra.intranet.ranges.wg-passthru) location subnet;
          mask = 64;
        };

        devices = [{
          interface = config.infra.intranet.devices.audrey.wireguard.passthru;
          presharedKeyFile = config.age.secrets.wg-audrey2whitelodge.path;
        }];
      };
    };
  };
}
