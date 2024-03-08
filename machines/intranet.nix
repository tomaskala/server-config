{ lib, ... }:

{
  options.networking.intranet = let
    networkInterface = lib.types.submodule {
      options = {
        name = lib.mkOption {
          type = lib.types.str;
          description = "Name of the network interface";
          example = "eth0";
          readOnly = true;
        };

        ipv4 = lib.mkOption {
          type = lib.types.str;
          description = "IPv4 address of the network interface";
          example = "192.168.0.1";
          readOnly = true;
        };

        ipv6 = lib.mkOption {
          type = lib.types.str;
          description = "IPv6 address of the network interface";
          example = "fe80::1";
          readOnly = true;
        };
      };
    };

    wireguardInterface = lib.types.submodule {
      options = {
        name = lib.mkOption {
          type = lib.types.str;
          description = "Name of the network interface";
          example = "eth0";
          readOnly = true;
        };

        publicKey = lib.mkOption {
          type = lib.types.str;
          description = "WireGuard public key of this peer";
          example = "C5sNSz31K8ihEavapHZp5ppfjyq3Q1vcTSvAhy2t+Eo=";
          readOnly = true;
        };

        port = lib.mkOption {
          type = lib.types.nullOr lib.types.port;
          description = "WireGuard port (unless to be automatically selected)";
          example = 51820;
          readOnly = true;
        };

        ipv4 = lib.mkOption {
          type = lib.types.str;
          description = "IPv4 address of the network interface";
          example = "192.168.0.1";
          readOnly = true;
        };

        ipv6 = lib.mkOption {
          type = lib.types.str;
          description = "IPv6 address of the network interface";
          example = "fe80::1";
          readOnly = true;
        };
      };
    };

    wireguardPeer = lib.types.submodule {
      options = {
        name = lib.mkOption {
          type = lib.types.str;
          description = "Name of this peer";
          example = "peer";
          readOnly = true;
        };

        interface = lib.mkOption {
          type = wireguardInterface;
          description = "WireGuard interface of this peer";
          readOnly = true;
        };
      };
    };

    subnet = let
      cidr = lib.types.submodule {
        options = {
          subnet = lib.mkOption {
            type = lib.types.str;
            description = "Subnet IP range";
            example = "10.0.0.0";
            readOnly = true;
          };

          mask = lib.mkOption {
            type = lib.types.int;
            description = "Subnet mask";
            example = 16;
            readOnly = true;
          };
        };
      };

      service = lib.types.submodule {
        options = {
          url = lib.mkOption {
            type = lib.types.str;
            description = "URL of the service";
            example = "service.home.arpa";
            readOnly = true;
          };

          ipv4 = lib.mkOption {
            type = lib.types.str;
            description = "IPv4 address of the service";
            example = "10.0.0.1";
            readOnly = true;
          };

          ipv6 = lib.mkOption {
            type = lib.types.str;
            description = "IPv6 address of the service";
            example = "fd25:6f6:a9f:2000::1";
            readOnly = true;
          };
        };
      };
    in lib.types.submodule {
      options = {
        ipv4 = lib.mkOption {
          type = cidr;
          description = "IPv4 range of the subnet";
          readOnly = true;
        };

        ipv6 = lib.mkOption {
          type = cidr;
          description = "IPv6 range of the subnet";
          readOnly = true;
        };

        gateway = lib.mkOption {
          type = lib.types.nullOr wireguardPeer;
          description = "VPN interface of this subnet";
          readOnly = true;
        };

        services = lib.mkOption {
          type = lib.types.attrsOf service;
          description = "Services running inside this subnet";
          default = { };
        };
      };
    };
  in {
    subnets = lib.mkOption {
      type = lib.types.attrsOf subnet;
      description = "Subnets inside the VPN";
    };

    external = lib.mkOption {
      type = lib.types.attrsOf networkInterface;
      description =
        "Network interfaces to external networks (outside of the intranet)";
      readOnly = true;
    };

    devices = lib.mkOption {
      type = lib.types.listOf wireguardPeer;
      description = "Devices connected to the network";
      readOnly = true;
    };
  };

  config.networking.intranet = let
    # IPv4: 10.<location>.<subnet>.0/<mask>
    mkIpv4Subnet = { location, subnet, mask ? 24 }: {
      subnet = "10.${builtins.toString location}.${builtins.toString subnet}.0";
      inherit mask;
    };

    # IPv6: fd25:6f6:<location>:<subnet>::/<mask>
    mkIpv6Subnet = { location, subnet, mask ? 64 }: {
      subnet =
        "fd25:6f6:${builtins.toString location}:${builtins.toString subnet}::";
      inherit mask;
    };

    # IPv4: 10.<location>.<subnet>.<host>
    mkIpv4Address = { location, subnet, host }:
      "10.${builtins.toString location}.${builtins.toString subnet}.${
        builtins.toString host
      }";

    # IPv6: fd25:6f6:<location>:<subnet>::<host>
    mkIpv6Address = { location, subnet, host }:
      "fd25:6f6:${builtins.toString location}:${builtins.toString subnet}::${
        builtins.toString host
      }";
  in {
    subnets = {
      # Devices in the internal subnet can communicate with each other
      # as well as access the public internet via the server.
      vpn-internal = {
        ipv4 = mkIpv4Subnet {
          location = 100;
          subnet = 100;
        };

        ipv6 = mkIpv6Subnet {
          location = 100;
          subnet = 100;
        };

        gateway = {
          name = "whitelodge";

          interface = {
            name = "wg-internal";
            publicKey = "a+x1ikWhkKubrcwipwj5UqKL3vE0NcqnjdNNcFXPXho=";
            port = 1194;

            ipv4 = mkIpv4Address {
              location = 100;
              subnet = 100;
              host = 1;
            };

            ipv6 = mkIpv6Address {
              location = 100;
              subnet = 100;
              host = 1;
            };
          };
        };
      };

      # Devices in the isolated subnet can communicate with each other,
      # but not access the public internet via the server.
      # Notably, this subnet should contain all gateways of non-VPN subnets,
      # because they only need to be accessible from the VPN, not access the
      # public internet through the server.
      vpn-isolated = {
        ipv4 = mkIpv4Subnet {
          location = 100;
          subnet = 104;
        };

        ipv6 = mkIpv6Subnet {
          location = 100;
          subnet = 104;
        };

        gateway = {
          name = "whitelodge";

          interface = {
            name = "wg-isolated";
            publicKey = "hDzNhJHJ6SJ81XasrZxPus5KDNCXwMb2IEq832GylxM=";
            port = 51820;

            ipv4 = mkIpv4Address {
              location = 100;
              subnet = 104;
              host = 1;
            };

            ipv6 = mkIpv6Address {
              location = 100;
              subnet = 104;
              host = 1;
            };
          };
        };
      };

      # Private L subnet containing trusted devices.
      l-private = {
        ipv4 = mkIpv4Subnet {
          location = 0;
          subnet = 0;
        };

        ipv6 = mkIpv6Subnet {
          location = 0;
          subnet = 0;
        };

        gateway = {
          name = "bob";

          interface = {
            name = "wg-private";
            publicKey = "mLT5Zqafn73bD6ZTyaMby6xM7Qm5i4CFau8vuqvTYkQ=";
            port = null;

            ipv4 = mkIpv4Address {
              location = 100;
              subnet = 104;
              host = 10;
            };

            ipv6 = mkIpv6Address {
              location = 100;
              subnet = 104;
              host = 10;
            };
          };
        };

        services = {
          router = {
            url = "router.l.home.arpa";

            ipv4 = mkIpv4Address {
              location = 0;
              subnet = 0;
              host = 1;
            };

            ipv6 = mkIpv6Address {
              location = 0;
              subnet = 0;
              host = 1;
            };
          };

          nas = {
            url = "nas.l.home.arpa";

            ipv4 = mkIpv4Address {
              location = 0;
              subnet = 0;
              host = 10;
            };

            ipv6 = mkIpv6Address {
              location = 0;
              subnet = 0;
              host = 10;
            };
          };
        };
      };

      # Isolated L subnet containing untrusted devices.
      l-isolated = {
        ipv4 = mkIpv4Subnet {
          location = 0;
          subnet = 1;
        };

        ipv6 = mkIpv6Subnet {
          location = 0;
          subnet = 1;
        };

        gateway = null;
      };

      # Private P subnet containing trusted devices.
      p-private = {
        ipv4 = mkIpv4Subnet {
          location = 1;
          subnet = 10;
        };

        ipv6 = mkIpv6Subnet {
          location = 1;
          subnet = 10;
        };

        gateway = null;

        services = {
          router = {
            url = "router.p.home.arpa";

            ipv4 = mkIpv4Address {
              location = 1;
              subnet = 10;
              host = 1;
            };

            ipv6 = mkIpv6Address {
              location = 1;
              subnet = 10;
              host = 1;
            };
          };
        };
      };

      # Isolated P subnet containing untrusted devices.
      p-isolated = {
        ipv4 = mkIpv4Subnet {
          location = 1;
          subnet = 20;
        };

        ipv6 = mkIpv6Subnet {
          location = 1;
          subnet = 20;
        };

        gateway = null;
      };
    };

    external = {
      whitelodge = {
        name = "venet0";
        ipv4 = "37.205.9.85";
        ipv6 = "2a01:430:17:1::ffff:1108";
      };

      bob = {
        name = "end0";

        ipv4 = mkIpv4Address {
          location = 0;
          subnet = 0;
          host = 2;
        };

        ipv6 = mkIpv6Address {
          location = 0;
          subnet = 0;
          host = 2;
        };
      };
    };

    devices = [
      {
        name = "cooper";
        interface = {
          name = "wg0";
          publicKey = "0F/gm1t4hV19N/U/GyB2laclS3CPfGDR2aA3f53EGXk=";
          port = null;

          ipv4 = mkIpv4Address {
            location = 100;
            subnet = 100;
            host = 50;
          };

          ipv6 = mkIpv6Address {
            location = 100;
            subnet = 100;
            host = 50;
          };
        };
      }
      {
        name = "blacklodge";
        interface = {
          name = "wg0";
          publicKey = "b1vNeOy10kbXfldKbaAd5xa2cndgzOE8kQ63HoWXIko=";
          port = null;

          ipv4 = mkIpv4Address {
            location = 100;
            subnet = 100;
            host = 51;
          };

          ipv6 = mkIpv6Address {
            location = 100;
            subnet = 100;
            host = 51;
          };
        };
      }
      {
        name = "tomas-phone";
        interface = {
          name = "wg0";
          publicKey = "OTH9T7YWk2sfBGGu6H4VAq/TdaFQkk2fL3fSoR1xnGo=";
          port = null;

          ipv4 = mkIpv4Address {
            location = 100;
            subnet = 100;
            host = 52;
          };

          ipv6 = mkIpv6Address {
            location = 100;
            subnet = 100;
            host = 52;
          };
        };
      }
    ];
  };
}
