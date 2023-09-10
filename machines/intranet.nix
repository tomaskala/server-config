{ lib, ... }:

{
  options.networking.intranet = let
    subnet = let
      ipRange = lib.types.submodule {
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
            example = "16";
            readOnly = true;
          };
        };
      };
    in lib.types.submodule {
      options = {
        ipv4 = lib.mkOption {
          type = ipRange;
          description = "IPv4 range of the subnet";
          readOnly = true;
        };

        ipv6 = lib.mkOption {
          type = ipRange;
          description = "IPv6 range of the subnet";
          readOnly = true;
        };
      };
    };

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
      readOnly = true;
    };

    gateways = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          internal = lib.mkOption {
            type = wireguardInterface;
            description = "Configuration of the WireGuard interface";
            readOnly = true;
          };

          external = lib.mkOption {
            type = networkInterface;
            description = "Configuration of the main external interface";
            readOnly = true;
          };

          network = lib.mkOption {
            type = lib.types.str;
            description = "Network in 'subnets' this gateway leads to";
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

    localDomains = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          ipv4 = lib.mkOption {
            type = lib.types.str;
            description = "IPv4 address the domain resolves to";
            example = "192.168.0.1";
            readOnly = true;
          };

          ipv6 = lib.mkOption {
            type = lib.types.str;
            description = "IPv6 address the domain resolves to";
            example = "fe80::1";
            readOnly = true;
          };
        };
      });
      description = "Locally-resolvable domains and their addresses";
      readOnly = true;
    };
  };

  config.networking.intranet = rec {
    subnets = {
      # Range of the entire intranet.
      intranet = {
        ipv4 = {
          subnet = "10.0.0.0";
          mask = 8;
        };

        ipv6 = {
          subnet = "fd25:6f6:a9f::";
          mask = 48;
        };
      };

      # Accessible by connecting to the server.
      vpn = {
        ipv4 = {
          subnet = "10.100.0.0";
          mask = 16;
        };

        ipv6 = {
          subnet = "fd25:6f6:a9f:1000::";
          mask = 52;
        };
      };

      # Devices in the internal subnet can communicate with each other
      # as well as access the public internet via the server.
      vpn-internal = {
        ipv4 = {
          subnet = "10.100.100.0";
          mask = 24;
        };
        ipv6 = {
          subnet = "fd25:6f6:a9f:1100::";
          mask = 56;
        };
      };

      # Devices in the isolated subnet can communicate with each other,
      # but not access the public internet via the server.
      vpn-isolated = {
        ipv4 = {
          subnet = "10.100.104.0";
          mask = 24;
        };
        ipv6 = {
          subnet = "fd25:6f6:a9f:1200::";
          mask = 56;
        };
      };

      # Accessible by connecting to the home gateway.
      home = {
        ipv4 = {
          subnet = "10.0.0.0";
          mask = 16;
        };

        ipv6 = {
          subnet = "fd25:6f6:a9f:2000::";
          mask = 52;
        };
      };

      # Private home subnet containing trusted devices.
      home-private = {
        ipv4 = {
          subnet = "10.0.0.0";
          mask = 24;
        };
        ipv6 = {
          subnet = "fd25:6f6:a9f:2100::";
          mask = 56;
        };
      };

      # Isolated home subnet containing untrusted devices.
      home-isolated = {
        ipv4 = {
          subnet = "10.0.4.0";
          mask = 24;
        };
        ipv6 = {
          subnet = "fd25:6f6:a9f:2200::";
          mask = 56;
        };
      };
    };

    gateways = {
      whitelodge = {
        internal = {
          interface = {
            name = "wg0";
            ipv4 = "10.100.0.1";
            ipv6 = "fd25:6f6:a9f:1000::1";
          };

          publicKey = "a+x1ikWhkKubrcwipwj5UqKL3vE0NcqnjdNNcFXPXho=";
          port = 1194;
        };

        external = {
          name = "venet0";
          ipv4 = "37.205.9.85";
          ipv6 = "2a01:430:17:1::ffff:1108";
        };

        network = "vpn";

        exporters = {
          node = {
            port = 9100;
            enabledCollectors = [ "processes" "systemd" ];
          };
        };
      };

      bob = {
        internal = {
          interface = {
            name = "wg0";
            ipv4 = "10.100.0.10";
            ipv6 = "fd25:6f6:a9f:1000::10";
          };

          publicKey = "mLT5Zqafn73bD6ZTyaMby6xM7Qm5i4CFau8vuqvTYkQ=";
          port = null;
        };

        external = {
          name = "end0";
          ipv4 = "10.0.0.2";
          ipv6 = "fd25:6f6:a9f:2000::2";
        };

        network = "home";

        exporters = { node.port = 9100; };
      };
    };

    # TODO: Also create an 'appliances' configuration for router & NAS?
    # Each would have a URL and IPs.
    # TODO Could also be 'services' to include music.home.arpa, which is on bob
    devices = {
      cooper = {
        interface = {
          name = "wg0";
          ipv4 = "10.100.100.1";
          ipv6 = "fd25:6f6:a9f:1100::1";
        };

        publicKey = "0F/gm1t4hV19N/U/GyB2laclS3CPfGDR2aA3f53EGXk=";
        port = null;
      };

      tomas-phone = {
        interface = {
          name = "wg0";
          ipv4 = "10.100.100.2";
          ipv6 = "fd25:6f6:a9f:1100::2";
        };

        publicKey = "DTJ3VeQGDehQBkYiteIpxtatvgqy2Ux/KjQEmXaEoEQ=";
        port = null;
      };

      blacklodge = {
        interface = {
          name = "wg0";
          ipv4 = "10.100.100.3";
          ipv6 = "fd25:6f6:a9f:1100::3";
        };

        publicKey = "b1vNeOy10kbXfldKbaAd5xa2cndgzOE8kQ63HoWXIko=";
        port = null;
      };

      martin-windows = {
        interface = {
          name = "wg0";
          ipv4 = "10.100.104.1";
          ipv6 = "fd25:6f6:a9f:1200::1";
        };

        publicKey = "JoxRQuYsNZqg/e/DHIVnAsDsA86PjyDlIWPIViMrPUQ=";
        port = null;
      };
    };

    localDomains = {
      "router.home.arpa" = {
        ipv4 = "10.0.0.1";
        ipv6 = "fd25:6f6:a9f:2000::1";
      };

      "music.home.arpa" = { inherit (gateways.bob.external) ipv4 ipv6; };

      "nas.home.arpa" = {
        ipv4 = "10.0.0.10";
        ipv6 = "fd25:6f6:a9f:2000::a";
      };
    };
  };
}
