{ config, lib, util, ... }:

{
  options.networking.intranet.devices = lib.mkOption {
    type = lib.types.attrsOf util.types.device;
    description = "Devices present in the intranet";
    readOnly = true;
  };

  # TODO: If we could store both VPN subnets and non-VPN subnets inside
  # each device's 'subnet' field, this would simplify vpn.nix
  config.networking.intranet.devices = {
    whitelodge = {
      wireguard = {
        internal = {
          name = "wg-internal";
          privateKeyFile = config.age.secrets.wg-vpn-internal-pk.path;
          publicKey = "a+x1ikWhkKubrcwipwj5UqKL3vE0NcqnjdNNcFXPXho=";
          port = 1194;
          subnet = null;

          ipv4 = {
            inherit (config.networking.intranet.ranges.vpn-internal)
              subnet location;
            host = 1;
          };

          ipv6 = {
            inherit (config.networking.intranet.ranges.vpn-internal)
              subnet location;
            host = 1;
          };
        };

        isolated = {
          name = "wg-isolated";
          privateKeyFile = config.age.secrets.wg-vpn-isolated-pk.path;
          publicKey = "hDzNhJHJ6SJ81XasrZxPus5KDNCXwMb2IEq832GylxM=";
          port = 51820;
          subnet = null;

          ipv4 = {
            inherit (config.networking.intranet.ranges.vpn-isolated)
              subnet location;
            host = 1;
          };

          ipv6 = {
            inherit (config.networking.intranet.ranges.vpn-isolated)
              subnet location;
            host = 1;
          };
        };

        passthru = {
          name = "wg-passthru";
          privateKeyFile = config.age.secrets.wg-vpn-passthru-pk.path;
          publicKey = "LT/LtBrD6n+i0Tyvleg1Eh8mWdskRUF5LXn0ynmwSg0=";
          port = 51821;
          subnet = null;

          ipv4 = {
            inherit (config.networking.intranet.ranges.vpn-passthru)
              subnet location;
            host = 1;
          };

          ipv6 = {
            inherit (config.networking.intranet.ranges.vpn-passthru)
              subnet location;
            host = 1;
          };
        };
      };

      external = {
        wan = {
          name = "venet0";
          ipv4 = "37.205.9.85";
          ipv6 = "2a01:430:17:1::ffff:1108";
        };
      };
    };

    bob = {
      wireguard = {
        isolated = {
          name = "wg0";
          privateKeyFile = config.age.secrets.wg-pk.path;
          publicKey = "mLT5Zqafn73bD6ZTyaMby6xM7Qm5i4CFau8vuqvTYkQ=";
          port = null;
          subnet = config.networking.intranet.subnets.l-internal;

          ipv4 = {
            inherit (config.networking.intranet.ranges.vpn-isolated)
              subnet location;
            host = 10;
          };

          ipv6 = {
            inherit (config.networking.intranet.ranges.vpn-isolated)
              subnet location;
            host = 10;
          };
        };
      };

      external = {
        lan = {
          name = "end0";

          ipv4 = {
            inherit (config.networking.intranet.ranges.l-internal)
              location subnet;
            host = 2;
          };

          ipv6 = {
            inherit (config.networking.intranet.ranges.l-internal)
              location subnet;
            host = 2;
          };
        };
      };
    };

    cooper = {
      wireguard = {
        internal = {
          name = "wg0";
          privateKeyFile = null;
          publicKey = "0F/gm1t4hV19N/U/GyB2laclS3CPfGDR2aA3f53EGXk=";
          port = null;
          subnet = null;

          ipv4 = {
            inherit (config.networking.intranet.ranges.vpn-internal)
              location subnet;
            host = 50;
          };

          ipv6 = {
            inherit (config.networking.intranet.ranges.vpn-internal)
              location subnet;
            host = 50;
          };
        };
      };
    };

    blacklodge = {
      wireguard = {
        internal = {
          name = "wg0";
          privateKeyFile = null;
          publicKey = "b1vNeOy10kbXfldKbaAd5xa2cndgzOE8kQ63HoWXIko=";
          port = null;
          subnet = null;

          ipv4 = {
            inherit (config.networking.intranet.ranges.vpn-internal)
              location subnet;
            host = 51;
          };

          ipv6 = {
            inherit (config.networking.intranet.ranges.vpn-internal)
              location subnet;
            host = 51;
          };
        };
      };
    };

    tomas-phone = {
      wireguard = {
        internal = {
          name = "wg0";
          privateKeyFile = null;
          publicKey = "OTH9T7YWk2sfBGGu6H4VAq/TdaFQkk2fL3fSoR1xnGo=";
          port = null;
          subnet = null;

          ipv4 = {
            inherit (config.networking.intranet.ranges.vpn-internal)
              location subnet;
            host = 52;
          };

          ipv6 = {
            inherit (config.networking.intranet.ranges.vpn-internal)
              location subnet;
            host = 52;
          };
        };
      };
    };

    audrey = {
      wireguard = {
        passthru = {
          name = "wg0";
          privateKeyFile = null;
          publicKey = "rmSz9L2CUhHqDbN+v9XOWU+UK1CwDMMwZIcDBBD931U=";
          port = null;
          subnet = config.networking.intranet.subnets.t-internal;

          ipv4 = {
            inherit (config.networking.intranet.ranges.vpn-passthru)
              location subnet;
            host = 10;
          };

          ipv6 = {
            inherit (config.networking.intranet.ranges.vpn-passthru)
              location subnet;
            host = 10;
          };
        };
      };
    };
  };
}
