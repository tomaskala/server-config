let
  wiredInterface = "eth0";
in {
  services.resolved = {
    enable = true;
    llmnr = "false";
    domains = [ "~." ];
    fallbackDns = [ "9.9.9.9" "149.112.112.112" "2620:fe::fe" "2620:fe::9" ];
  };

  systemd.network = {
    enable = true;

    networks."10-${wiredInterface}" = {
      matchConfig.Name = wiredInterface;

      networkConfig = {
        DHCP = "yes";
        IPv6AcceptRA = true;
        IPv6PrivacyExtensions = true;
      };

      dhcpV4Config.Anonymize = true;
    };
  };

  networking = {
    dhcpcd.enable = false;
    useDHCP = false;
    useNetworkd = true;

    wireless.iwd = {
      enable = true;

      settings = {
        General = {
          EnableNetworkConfiguration = true;
          AddressRandomization = "once";
        };

        Network = {
          EnableIPv6 = true;
          NameResolvingService = "systemd";
        };

        Scan.DisablePeriodicScan = true;
      };
    };
  };
}
