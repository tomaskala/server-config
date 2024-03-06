{ config, lib, ... }:

let
  cfg = config.services.vpn;
  intranetCfg = config.networking.intranet;
  gatewayCfg = intranetCfg.gateways.whitelodge;

  vpnInterface = gatewayCfg.internal.interface.name;
  vpnSubnet = intranetCfg.subnets.vpn;
in {
  options.services.vpn = { enable = lib.mkEnableOption "vpn"; };

  config = lib.mkIf cfg.enable {
    systemd.network = {
      enable = true;

      netdevs."90-${vpnInterface}" = {
        netdevConfig = {
          Name = vpnInterface;
          Kind = "wireguard";
        };

        wireguardConfig = {
          PrivateKeyFile = config.age.secrets.wg-pk.path;
          ListenPort = gatewayCfg.internal.port;
        };

        wireguardPeers = [
          {
            wireguardPeerConfig = {
              # cooper
              PublicKey = intranetCfg.devices.cooper.publicKey;
              PresharedKeyFile = config.age.secrets.wg-cooper2whitelodge.path;
              AllowedIPs = [
                "${intranetCfg.devices.cooper.interface.ipv4}/32"
                "${intranetCfg.devices.cooper.interface.ipv6}/128"
              ];
            };
          }
          {
            wireguardPeerConfig = {
              # tomas-phone
              PublicKey = intranetCfg.devices.tomas-phone.publicKey;
              PresharedKeyFile =
                config.age.secrets.wg-tomas-phone2whitelodge.path;
              AllowedIPs = [
                "${intranetCfg.devices.tomas-phone.interface.ipv4}/32"
                "${intranetCfg.devices.tomas-phone.interface.ipv6}/128"
              ];
            };
          }
          {
            wireguardPeerConfig = {
              # blacklodge
              PublicKey = intranetCfg.devices.blacklodge.publicKey;
              PresharedKeyFile =
                config.age.secrets.wg-blacklodge2whitelodge.path;
              AllowedIPs = [
                "${intranetCfg.devices.blacklodge.interface.ipv4}/32"
                "${intranetCfg.devices.blacklodge.interface.ipv6}/128"
              ];
            };
          }
        ];
      };

      networks."90-${vpnInterface}" = {
        matchConfig.Name = vpnInterface;

        address = [
          "${gatewayCfg.internal.interface.ipv4}/${
            builtins.toString vpnSubnet.ipv4.mask
          }"
          "${gatewayCfg.internal.interface.ipv6}/${
            builtins.toString vpnSubnet.ipv6.mask
          }"
        ];
      };
    };

  };
}
