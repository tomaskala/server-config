{ config, lib, pkgs, ... }:

let inherit (pkgs) infra;
in {
  options.infra.intranet.devices = lib.mkOption {
    type = lib.types.attrsOf infra.types.device;
    description = "Devices present in the intranet";
    readOnly = true;
  };

  # TODO: If we could store both WireGuard subnets and non-WireGuard subnets
  # inside each device's 'subnet' field, this would simplify wireguard.nix
  config = {
    infra.intranet.devices = {
      whitelodge = {
        wireguard = {
          internal = {
            name = "wg-internal";
            privateKeyFile = config.age.secrets.wg-whitelodge-internal-pk.path;
            publicKey = "a+x1ikWhkKubrcwipwj5UqKL3vE0NcqnjdNNcFXPXho=";
            port = 1194;
            subnet = null;

            ipv4 = {
              inherit (config.infra.intranet.ranges.wg-internal)
                subnet location;
              host = 1;
            };

            ipv6 = {
              inherit (config.infra.intranet.ranges.wg-internal)
                subnet location;
              host = 1;
            };
          };

          isolated = {
            name = "wg-isolated";
            privateKeyFile = config.age.secrets.wg-whitelodge-isolated-pk.path;
            publicKey = "hDzNhJHJ6SJ81XasrZxPus5KDNCXwMb2IEq832GylxM=";
            port = 51820;
            subnet = null;

            ipv4 = {
              inherit (config.infra.intranet.ranges.wg-isolated)
                subnet location;
              host = 1;
            };

            ipv6 = {
              inherit (config.infra.intranet.ranges.wg-isolated)
                subnet location;
              host = 1;
            };
          };

          passthru = {
            name = "wg-passthru";
            privateKeyFile = config.age.secrets.wg-whitelodge-passthru-pk.path;
            publicKey = "LT/LtBrD6n+i0Tyvleg1Eh8mWdskRUF5LXn0ynmwSg0=";
            port = 51821;
            subnet = null;

            ipv4 = {
              inherit (config.infra.intranet.ranges.wg-passthru)
                subnet location;
              host = 1;
            };

            ipv6 = {
              inherit (config.infra.intranet.ranges.wg-passthru)
                subnet location;
              host = 1;
            };
          };
        };

        external = {
          wan = {
            name = "venet0";
            ipv4 = "37.205.9.85";
            ipv6 = "2a03:3b40:fe:c7::1";
          };
        };
      };

      bob = {
        wireguard = {
          isolated = {
            name = "wg0";
            privateKeyFile = config.age.secrets.wg-bob-isolated-pk.path;
            publicKey = "mLT5Zqafn73bD6ZTyaMby6xM7Qm5i4CFau8vuqvTYkQ=";
            port = null;
            subnet = config.infra.intranet.subnets.l-internal;

            ipv4 = {
              inherit (config.infra.intranet.ranges.wg-isolated)
                subnet location;
              host = 10;
            };

            ipv6 = {
              inherit (config.infra.intranet.ranges.wg-isolated)
                subnet location;
              host = 10;
            };
          };
        };

        external = {
          lan = {
            name = "end0";

            ipv4 = {
              inherit (config.infra.intranet.ranges.l-internal) location subnet;
              host = 2;
            };

            ipv6 = {
              inherit (config.infra.intranet.ranges.l-internal) location subnet;
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
              inherit (config.infra.intranet.ranges.wg-internal)
                location subnet;
              host = 50;
            };

            ipv6 = {
              inherit (config.infra.intranet.ranges.wg-internal)
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
            publicKey = "iiES+M3jIP4XUD1X4G/mh4lwKbhtTVjjvhTtHCweLH4=";
            port = null;
            subnet = null;

            ipv4 = {
              inherit (config.infra.intranet.ranges.wg-internal)
                location subnet;
              host = 51;
            };

            ipv6 = {
              inherit (config.infra.intranet.ranges.wg-internal)
                location subnet;
              host = 51;
            };
          };
        };
      };

      hawk = {
        wireguard = {
          internal = {
            name = "wg0";
            privateKeyFile = null;
            publicKey = "OTH9T7YWk2sfBGGu6H4VAq/TdaFQkk2fL3fSoR1xnGo=";
            port = null;
            subnet = null;

            ipv4 = {
              inherit (config.infra.intranet.ranges.wg-internal)
                location subnet;
              host = 52;
            };

            ipv6 = {
              inherit (config.infra.intranet.ranges.wg-internal)
                location subnet;
              host = 52;
            };
          };
        };
      };

      gordon = {
        wireguard = {
          internal = {
            name = "wg0";
            privateKeyFile = null;
            publicKey = "rPkDvc0kutSN4hE+lIIk/tMj6IGlaXUB1Z4NlmHZpRA=";
            port = null;
            subnet = null;

            ipv4 = {
              inherit (config.infra.intranet.ranges.wg-internal)
                location subnet;
              host = 53;
            };

            ipv6 = {
              inherit (config.infra.intranet.ranges.wg-internal)
                location subnet;
              host = 53;
            };
          };
        };
      };

      audrey = {
        wireguard = {
          passthru = {
            name = "wg0";
            privateKeyFile = null;
            publicKey = "CLJaT0cZMQIC7gPd7aVuiJiJqGMKO5zwaRUYVdUnuwQ=";
            port = null;
            subnet = config.infra.intranet.subnets.t-internal;

            ipv4 = {
              inherit (config.infra.intranet.ranges.wg-passthru)
                location subnet;
              host = 10;
            };

            ipv6 = {
              inherit (config.infra.intranet.ranges.wg-passthru)
                location subnet;
              host = 10;
            };
          };
        };
      };
    };
  };
}
