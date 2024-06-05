{ config, lib, pkgs, ... }:

let inherit (pkgs) infra;
in {
  options.infra.intranet.subnets = lib.mkOption {
    type = lib.types.attrsOf infra.types.nonWgSubnet;
    description = "Subnets in the intranet accessible from WireGuard";
  };

  config.infra.intranet.subnets = {
    l-internal = {
      ipv4 = {
        inherit (config.infra.intranet.ranges.l-internal) location subnet;
        mask = 24;
      };

      ipv6 = {
        inherit (config.infra.intranet.ranges.l-internal) location subnet;
        mask = 64;
      };

      services = {
        nas = {
          url = "nas.l.home.arpa";

          ipv4 = {
            inherit (config.infra.intranet.ranges.l-internal) location subnet;
            host = 10;
          };

          ipv6 = {
            inherit (config.infra.intranet.ranges.l-internal) location subnet;
            host = 10;
          };
        };

        printer = {
          url = "printer.l.home.arpa";

          ipv4 = {
            inherit (config.infra.intranet.ranges.l-internal) location subnet;
            host = 11;
          };

          ipv6 = {
            inherit (config.infra.intranet.ranges.l-internal) location subnet;
            host = 11;
          };
        };
      };
    };

    p-internal = {
      ipv4 = {
        inherit (config.infra.intranet.ranges.p-internal) location subnet;
        mask = 24;
      };

      ipv6 = {
        inherit (config.infra.intranet.ranges.p-internal) location subnet;
        mask = 64;
      };
    };

    t-internal = {
      ipv4 = {
        inherit (config.infra.intranet.ranges.t-internal) location subnet;
        mask = 24;
      };

      ipv6 = {
        inherit (config.infra.intranet.ranges.t-internal) location subnet;
        mask = 64;
      };
    };
  };
}
