{
  config = {
    maskedSubnet = { subnet, mask }: "${subnet}/${builtins.toString mask}";

    intranet = {
      # IP ranges of the entire intranet.
      ipv4 = {
        subnet = "10.100.0.0";
        mask = 16;
      };
      ipv6 = {
        subnet = "fd25:6f6:a9f:1000::";
        mask = 52;
      };

      # Subnets within the VPN tunnel.
      subnets = {
        # Devices in the internal subnet can communicate with each other
        # as well as access the public internet via the server.
        internal.ipv4 = {
          subnet = "10.100.100.0";
          mask = 24;
        };
        internal.ipv6 = {
          subnet = "fd25:6f6:a9f:1100::";
          mask = 56;
        };

        # Devices in the isolated subnet can communicate with each other,
        # but not access the public internet via the server.
        isolated.ipv4 = {
          subnet = "10.100.104.0";
          mask = 24;
        };
        isolated.ipv6 = {
          subnet = "fd25:6f6:a9f:1200::";
          mask = 56;
        };
      };

      # Configuration of the server VPN interface.
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
            ipv4 = "10.0.0.0/16";
            ipv6 = "fd25:6f6:a9f:2000::/52";
          };
        };
      };

      # Domains resolvable inside the VPN tunnel.
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
