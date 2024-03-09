{ config, ... }:

let
  deviceCfg = config.networking.intranet.devices.bob;
  lanInterface = deviceCfg.external.lan.name;
in {
  systemd.network = {
    enable = true;

    networks."10-${lanInterface}" = {
      matchConfig.Name = lanInterface;

      networkConfig = {
        DHCP = "yes";
        IPv6AcceptRA = true;
        IPv6PrivacyExtensions = true;
      };
    };
  };

  networking = {
    dhcpcd.enable = false;
    useDHCP = false;
    useNetworkd = true;
  };
}
