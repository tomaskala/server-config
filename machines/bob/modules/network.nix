{ config, ... }:

let
  intranetCfg = config.networking.intranet;
  lanInterface = intranetCfg.gateways.bob.external.name;
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
