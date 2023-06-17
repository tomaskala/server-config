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
          };

          mask = lib.mkOption {
            type = lib.types.int;
            description = "Subnet mask";
            example = "16";
          };
        };
      };
    in lib.types.submodule {
      options = {
        ipv4 = lib.mkOption {
          type = ipRange;
          description = "IPv4 range of the subnet";
        };

        ipv6 = lib.mkOption {
          type = ipRange;
          description = "IPv6 range of the subnet";
        };
      };
    };

    networkInterface = lib.types.submodule {
      options = {
        name = lib.mkOption {
          type = lib.types.str;
          description = "Name of the network interface";
          example = "eth0";
        };

        ipv4 = lib.mkOption {
          type = lib.types.str;
          description = "IPv4 address of the network interface";
          example = "192.168.0.1";
        };

        ipv6 = lib.mkOption {
          type = lib.types.str;
          description = "IPv6 address of the network interface";
          example = "fe80::1";
        };
      };
    };

    wireguardInterface = lib.types.submodule {
      options = {
        interface = lib.mkOption {
          type = networkInterface;
          description = "WireGuard interface of this peer";
        };

        publicKey = lib.mkOption {
          type = lib.types.str;
          description = "WireGuard public key of this peer";
          example = "C5sNSz31K8ihEavapHZp5ppfjyq3Q1vcTSvAhy2t+Eo=";
        };

        port = lib.mkOption {
          type = lib.types.nullOr lib.types.port;
          description = "WireGuard port (unless to be automatically selected)";
          example = 51820;
        };
      };
    };
  in {
    subnets = lib.mkOption {
      type = lib.types.attrsOf subnet;
      description = "Subnets inside the VPN";
    };

    peers = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          internal = lib.mkOption {
            type = wireguardInterface;
            description = "Configuration of the WireGuard interface";
          };

          external = lib.mkOption {
            type = networkInterface;
            description = "Configuration of the main external interface";
          };

          network = lib.mkOption {
            type = subnet;
            description = "Network this peer is a gateway to";
          };
        };
      });
      description = ''
        Peers connected to the intranet. Each consists of the WireGuard
        interface used to connect to the intranet, the main external interface
        (public IP address in case of the server, LAN interface in case of
        a peer behind a NAT), and the network that the peer is a gateway to.
      '';
    };

    localDomains = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          ipv4 = lib.mkOption {
            type = lib.types.str;
            description = "IPv4 address the domain resolves to";
            example = "192.168.0.1";
          };

          ipv6 = lib.mkOption {
            type = lib.types.str;
            description = "IPv6 address the domain resolves to";
            example = "fe80::1";
          };
        };
      });
      description = "Locally-resolvable domains and their addresses";
    };
  };

  config.networking.intranet = rec {
    subnets = {
      # Devices in the internal subnet can communicate with each other
      # as well as access the public internet via the server.
      internal = {
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
      isolated = {
        ipv4 = {
          subnet = "10.100.104.0";
          mask = 24;
        };
        ipv6 = {
          subnet = "fd25:6f6:a9f:1200::";
          mask = 56;
        };
      };
    };

    peers = {
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

        network = {
          ipv4 = {
            subnet = "10.100.0.0";
            mask = 16;
          };

          ipv6 = {
            subnet = "fd25:6f6:a9f:1000::";
            mask = 52;
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

          publicKey = "AA8z9EaVsdss2agi0V7Hho8xe+mMlVUJpqgZcp4D5Eg=";
          port = null;
        };

        external = {
          name = "eth0";
          ipv4 = "10.0.0.2";
          ipv6 = "fd25:6f6:a9f:2000::2";
        };

        network = {
          ipv4 = {
            subnet = "10.0.0.0";
            mask = 16;
          };

          ipv6 = {
            subnet = "fd25:6f6:a9f:2000::";
            mask = 52;
          };
        };
      };
    };

    localDomains = {
      "router.home.arpa" = {
        ipv4 = "10.0.0.1";
        ipv6 = "fd25:6f6:a9f:2000::1";
      };

      "music.home.arpa" = { inherit (peers.bob.external) ipv4 ipv6; };

      "nas.home.arpa" = {
        ipv4 = "10.0.0.10";
        ipv6 = "fd25:6f6:a9f:2000::a";
      };
    };
  };
}
