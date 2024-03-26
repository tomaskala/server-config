{ config, lib, util, ... }:

{
  options.networking.intranet.subnets = lib.mkOption {
    type = lib.types.attrsOf util.types.nonVpnSubnet;
    description = "Subnets in the intranet accessible from the VPN";
  };

  config.networking.intranet.subnets = {
    l-internal = {
      ipv4 = {
        inherit (config.networking.intranet.ranges.l-internal) location subnet;
        mask = 24;
      };

      ipv6 = {
        inherit (config.networking.intranet.ranges.l-internal) location subnet;
        mask = 64;
      };

      services = {
        nas = {
          url = "nas.l.home.arpa";

          ipv4 = {
            inherit (config.networking.intranet.ranges.l-internal)
              location subnet;
            host = 10;
          };

          ipv6 = {
            inherit (config.networking.intranet.ranges.l-internal)
              location subnet;
            host = 10;
          };
        };
      };
    };

    p-internal = {
      ipv4 = {
        inherit (config.networking.intranet.ranges.p-internal) location subnet;
        mask = 24;
      };

      ipv6 = {
        inherit (config.networking.intranet.ranges.p-internal) location subnet;
        mask = 64;
      };
    };

    t-internal = {
      ipv4 = {
        inherit (config.networking.intranet.ranges.t-internal) location subnet;
        mask = 24;
      };

      ipv6 = {
        inherit (config.networking.intranet.ranges.t-internal) location subnet;
        mask = 64;
      };
    };
  };
}
