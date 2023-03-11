{ ... }:

{
  maskedSubnet = { subnet, mask }: "${subnet}/${mask}";

  intranet = {
    ipv4 = { subnet = "10.100.0.0"; mask = 16; };
    ipv6 = { subnet = "fd25:6f6:a9f:1000::"; mask = 52; };

    subnets = {
      internal.ipv4 = { subnet = "10.100.100.0"; mask = 24; };
      internal.ipv6 = { subnet = "fd25:6f6:a9f:1100::"; mask = 56; };

      isolated.ipv4 = { subnet = "10.100.104.0"; mask = 24; };
      isolated.ipv6 = { subnet = "fd25:6f6:a9f:1200::"; mask = 56; };
    };

    server = {
      ipv4 = "10.100.0.1";
      ipv6 = "fd25:6f6:a9f:1000::1";
      port = 1194;
      interface = "wg0";
    };
  };
}
