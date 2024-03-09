{ lib, ... }:

{
  options.networking.intranet.ranges = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule {
      options = {
        location = lib.mkOption {
          type = lib.types.int;
          description = "Location within the intranet";
          readOnly = true;
        };

        subnet = lib.mkOption {
          type = lib.types.int;
          description = "Subnet within this IP address' location";
          readOnly = true;
        };
      };
    });
    description = ''
      A range describes the location and subnet numbers of a particular subnet.
      These are to be extended into an IP address type or an IP subnet type,
      and converted to string using one of the utility functions.
    '';
    readOnly = true;
  };

  config.networking.intranet.ranges = {
    vpn-internal = {
      location = 100;
      subnet = 100;
    };

    vpn-isolated = {
      location = 100;
      subnet = 104;
    };

    vpn-passthru = {
      location = 100;
      subnet = 108;
    };

    l-internal = {
      location = 0;
      subnet = 0;
    };

    p-internal = {
      location = 1;
      subnet = 10;
    };
  };
}
