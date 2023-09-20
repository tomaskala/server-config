let
  wiredInterface = "eth0";
  wirelessInterface = "wlan0";
in {
  services.resolved = {
    enable = true;
    llmnr = "false";
    domains = [ "home.arpa" ];
  };

  systemd.network = {
    enable = true;

    networks."10-${wiredInterface}" = {
      matchConfig.Name = wiredInterface;

      networkConfig = {
        DHCP = true;
        IPv6AcceptRA = true;
        IPv6PrivacyExtensions = true;
      };

      dhcpV4Config.Anonymize = true;
    };
  };

  networking = {
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

  environment.persistence."/persistent".directories = [ "/var/lib/iwd" ];

  # Wait until udev renames the wireless interface.
  systemd.services.iwd =
    let deps = [ "sys-subsystem-net-devices-${wirelessInterface}.device" ];
    in {
      requires = deps;
      after = deps;
    };
}
