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
          description = "Name of this peer";
          example = "peer";
          readOnly = true;
        };

        interface = lib.mkOption {
          type = networkInterface;
          description = "WireGuard interface of this peer";
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
          };

          ipv4 = lib.mkOption {
            type = lib.types.str;
            description = "IPv4 address of the service";
            example = "10.0.0.1";
          };

          ipv6 = lib.mkOption {
            type = lib.types.str;
            description = "IPv6 address of the service";
            example = "fd25:6f6:a9f:2000::1";
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
          type = lib.types.nullOr wireguardInterface;
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

    exporter = lib.types.submodule {
      freeformType = lib.types.attrs;

      options = {
        port = lib.mkOption {
          type = lib.types.port;
          description = "Port the Prometheus exporter listens on";
          example = 9100;
          readOnly = true;
        };
      };
    };
  in {
    subnets = lib.mkOption {
      type = lib.types.attrsOf subnet;
      description = "Subnets inside the VPN";
    };

    gateways = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          external = lib.mkOption {
            type = networkInterface;
            description = "Configuration of the main external interface";
            readOnly = true;
          };

          exporters = lib.mkOption {
            type = lib.types.attrsOf exporter;
            description = "Prometheus exporters configuration";
            example = { node.port = 9100; };
            readOnly = true;
          };
        };
      });
      description = ''
        Gateways connected to the intranet. Each consists of the WireGuard
        interface used to connect to the intranet, the main external interface
        (public IP address in case of the server, LAN interface in case of
        a gateway behind a NAT), and the network that the gateway leads to.
      '';
      readOnly = true;
    };

    devices = lib.mkOption {
      type = lib.types.attrsOf wireguardInterface;
      description = "Devices connected to the network not serving as gateways";
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
      # Range of the entire intranet.
      intranet = {
        ipv4 = mkIpv4Subnet {
          location = 0;
          subnet = 0;
          mask = 8;
        };

        ipv6 = mkIpv6Subnet {
          location = 0;
          subnet = 0;
          mask = 48;
        };

        gateway = null;
      };

      # Accessible by connecting to the server.
      vpn = {
        ipv4 = mkIpv4Subnet {
          location = 100;
          subnet = 0;
          mask = 16;
        };

        ipv6 = mkIpv6Subnet {
          location = 100;
          subnet = 0;
          mask = 56;
        };

        gateway = null;
      };

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

          publicKey = "a+x1ikWhkKubrcwipwj5UqKL3vE0NcqnjdNNcFXPXho=";
          port = 1194;
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

          publicKey = "";
          port = 1194;
        };
      };

      # Entire L subnet.
      l = {
        ipv4 = mkIpv4Subnet {
          location = 0;
          subnet = 0;
          mask = 16;
        };

        ipv6 = mkIpv6Subnet {
          location = 0;
          subnet = 0;
          mask = 56;
        };

        gateway = null;
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

          publicKey = "mLT5Zqafn73bD6ZTyaMby6xM7Qm5i4CFau8vuqvTYkQ=";
          port = null;
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

      # Entire P subnet.
      p = {
        ipv4 = mkIpv4Subnet {
          location = 1;
          subnet = 0;
          mask = 16;
        };

        ipv6 = mkIpv6Subnet {
          location = 1;
          subnet = 0;
          mask = 56;
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

    gateways = {
      whitelodge = {
        external = {
          name = "venet0";
          ipv4 = "37.205.9.85";
          ipv6 = "2a01:430:17:1::ffff:1108";
        };

        exporters = {
          node = {
            port = 9100;
            enabledCollectors = [ "processes" "systemd" ];
          };
        };
      };

      bob = {
        external = {
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

        exporters = { node.port = 9100; };
      };
    };

    devices = {
      cooper = {
        name = "cooper";

        interface = {
          name = "wg0";

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

        publicKey = "0F/gm1t4hV19N/U/GyB2laclS3CPfGDR2aA3f53EGXk=";
        port = null;
      };

      blacklodge = {
        name = "blacklodge";

        interface = {
          name = "wg0";

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

        publicKey = "b1vNeOy10kbXfldKbaAd5xa2cndgzOE8kQ63HoWXIko=";
        port = null;
      };

      tomas-phone = {
        name = "tomas-phone";

        interface = {
          name = "wg0";

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

        publicKey = "OTH9T7YWk2sfBGGu6H4VAq/TdaFQkk2fL3fSoR1xnGo=";
        port = null;
      };
    };
  };
}
