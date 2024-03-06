{ config, lib, ... }:

let
  cfg = config.services.vpn;
  intranetCfg = config.networking.intranet;
  gatewayCfg = intranetCfg.subnets.l-private.gateway;

  vpnInterface = gatewayCfg.interface.name;
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

        wireguardConfig = { PrivateKeyFile = config.age.secrets.wg-pk.path; };

        wireguardPeers = [{
          wireguardPeerConfig = {
            # whitelodge
            PublicKey = intranetCfg.subnets.vpn-isolated.gateway.publicKey;
            PresharedKeyFile = config.age.secrets.wg-bob2whitelodge.path;
            AllowedIPs = [
              "${intranetCfg.subnets.vpn-isolated.gateway.interface.ipv4}/32"
              "${intranetCfg.subnets.vpn-isolated.gateway.interface.ipv6}/128"
            ];
            Endpoint = "${intranetCfg.gateways.whitelodge.external.ipv4}:${
                builtins.toString intranetCfg.subnets.vpn-isolated.gateway.port
              }";
            PersistentKeepalive = 25;
          };
        }];
      };

      networks."90-${vpnInterface}" = {
        matchConfig.Name = vpnInterface;

        # Enable IP forwarding (system-wide).
        networkConfig.IPForward = true;

        address = [
          "${gatewayCfg.interface.ipv4}/${
            builtins.toString vpnSubnet.ipv4.mask
          }"
          "${gatewayCfg.interface.ipv6}/${
            builtins.toString vpnSubnet.ipv6.mask
          }"
        ];
      };
    };
  };
}
