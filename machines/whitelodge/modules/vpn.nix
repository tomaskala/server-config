{ config, lib, ... }:

let
  cfg = config.services.vpn;
  intranetCfg = config.networking.intranet;
in {
  options.services.vpn = { enable = lib.mkEnableOption "vpn"; };

  config = lib.mkIf cfg.enable {
    systemd.network = {
      enable = true;

      netdevs."90-${intranetCfg.subnets.vpn-internal.gateway.interface.name}" =
        {
          netdevConfig = {
            Name = intranetCfg.subnets.vpn-internal.gateway.interface.name;
            Kind = "wireguard";
          };

          wireguardConfig = {
            PrivateKeyFile = config.age.secrets.wg-vpn-internal-pk.path;
            ListenPort = intranetCfg.subnets.vpn-internal.gateway.port;
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

      networks."90-${intranetCfg.subnets.vpn-internal.gateway.interface.name}" =
        {
          matchConfig.Name =
            intranetCfg.subnets.vpn-internal.gateway.interface.name;
          address = [
            "${intranetCfg.subnets.vpn-internal.gateway.interface.ipv4}/${
              builtins.toString intranetCfg.subnets.vpn-internal.ipv4.mask
            }"
            "${intranetCfg.subnets.vpn-internal.gateway.interface.ipv6}/${
              builtins.toString intranetCfg.subnets.vpn-internal.ipv6.mask
            }"
          ];
        };
    };
  };
}
