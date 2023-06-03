{ lib, ... }:

{
  options.networking.intranet = let
    subnet = lib.types.submodule {
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

    domain = lib.types.submodule {
      options = {
        domain = lib.mkOption {
          type = lib.types.str;
          description = "Locally resolvable domain";
          example = "example.home.arpa";
        };

        ipv4 = lib.mkOption {
          type = lib.types.str;
          description = "IPv4 address the domain resolves to (the A record)";
          example = "10.0.0.1";
        };

        ipv6 = lib.mkOption {
          type = lib.types.str;
          description = "IPv6 address the domain resolves to (the AAAA record)";
          example = "fd25::1";
        };
      };
    };

    server = lib.types.submodule {
      options = {
        ipv4 = lib.mkOption {
          type = lib.types.str;
          description = "Server's IPv4 address in the VPN";
          example = "10.100.0.1";
        };

        ipv6 = lib.mkOption {
          type = lib.types.str;
          description = "Server's IPv6 address in the VPN";
          example = "fd25:6f6:a9f:1000::1";
        };

        port = lib.mkOption {
          type = lib.types.port;
          description = "Port the VPN server listens on";
          example = 51820;
        };

        interface = lib.mkOption {
          type = lib.types.str;
          description = "Name of the server's VPN interface";
          example = "wg0";
        };
      };
    };

    gateway = lib.types.submodule {
      options = {
        ipv4 = lib.mkOption {
          type = lib.types.str;
          description = "Gateway's IPv4 address in the VPN";
        };

        ipv6 = lib.mkOption {
          type = lib.types.str;
          description = "Gateway's IPv6 address in the VPN";
        };

        publicKey = lib.mkOption {
          type = lib.types.str;
          description = "Gateway's public key";
        };
      };
    };
  in {
    ipv4 = lib.mkOption {
      type = subnet;
      description = "IPv4 range of the entire intranet";
    };

    ipv6 = lib.mkOption {
      type = subnet;
      description = "IPv6 range of the entire intranet";
    };

    subnets = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          ipv4 = lib.mkOption {
            type = subnet;
            description = "IPv4 range of the subnet";
          };

          ipv6 = lib.mkOption {
            type = subnet;
            description = "IPv6 range of the subnet";
          };
        };
      });
      description = "Subnets within the VPN";
    };

    server = lib.mkOption {
      type = server;
      description = "Configuration of the server VPN interface";
    };

    locations = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          gateway = lib.mkOption {
            type = gateway;
            description = "IP addresses and a public key of the VPN gateway";
          };

          subnet = lib.mkOption {
            type = lib.types.submodule {
              options = {
                ipv4 = lib.mkOption {
                  type = subnet;
                  description = "IPv4 range of the subnet";
                };

                ipv6 = lib.mkOption {
                  type = subnet;
                  description = "IPv6 range of the subnet";
                };
              };
            };
            description = "IPv4 and IPv6 ranges of the subnet";
          };
        };
      });
      description =
        "Locations connected to the VPN, each consisting of a gateway and a subnet.";
    };

    localDomains = lib.mkOption {
      type = lib.types.listOf domain;
      description = "Locally-resolvable domains and their addresses";
    };
  };

  config = {
    intranet = {
      ipv4 = {
        subnet = "10.100.0.0";
        mask = 16;
      };

      ipv6 = {
        subnet = "fd25:6f6:a9f:1000::";
        mask = 52;
      };

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

      server = {
        ipv4 = "10.100.0.1";
        ipv6 = "fd25:6f6:a9f:1000::1";
        port = 1194;
        interface = "wg0";
      };

      # Each location consists of a subnet and a gateway. The gateway is
      # connected to the VPN and consists of its addresses within the tunnel
      # and a public key. The preshared key is looked up based on the location
      # name. All traffic destined to the location's subnet is routed through
      # the gateway inside the VPN tunnel.
      locations = {
        home = {
          gateway = {
            ipv4 = "10.100.0.10";
            ipv6 = "fd25:6f6:a9f:1000::10";
            publicKey = "AA8z9EaVsdss2agi0V7Hho8xe+mMlVUJpqgZcp4D5Eg=";
          };

          subnet = {
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

      localDomains = [
        {
          domain = "router.home.arpa";
          ipv4 = "10.0.0.1";
          ipv6 = "fd25:6f6:a9f:2000::1";
        }
        {
          domain = "bob.home.arpa";
          ipv4 = "10.0.0.2";
          ipv6 = "fd25:6f6:a9f:2000::2";
        }
        {
          domain = "mike.home.arpa";
          ipv4 = "10.0.0.3";
          ipv6 = "fd25:6f6:a9f:2000::3";
        }
        {
          domain = "nas.home.arpa";
          ipv4 = "10.0.0.10";
          ipv6 = "fd25:6f6:a9f:2000::a";
        }
        {
          domain = "music.home.arpa";
          ipv4 = "10.0.0.2";
          ipv6 = "fd25:6f6:a9f:2000::2";
        }
      ];
    };
  };
}
