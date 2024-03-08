{ config, lib, ... }:

let
  cfg = config.services.vpn;
  intranetCfg = config.networking.intranet;
in {
  options.services.vpn = { enable = lib.mkEnableOption "vpn"; };

  config = lib.mkIf cfg.enable {
    systemd.network = {
      enable = true;

      netdevs."90-${intranetCfg.subnets.l-private.gateway.interface.name}" = {
        netdevConfig = {
          Name = intranetCfg.subnets.l-private.gateway.interface.name;
          Kind = "wireguard";
        };

        wireguardConfig = { PrivateKeyFile = config.age.secrets.wg-pk.path; };

        wireguardPeers = [{
          wireguardPeerConfig = {
            # whitelodge
            PublicKey =
              intranetCfg.subnets.vpn-isolated.gateway.interface.publicKey;
            PresharedKeyFile = config.age.secrets.wg-bob2whitelodge.path;
            AllowedIPs = [
              "${intranetCfg.subnets.vpn-isolated.gateway.interface.ipv4}/32"
              "${intranetCfg.subnets.vpn-isolated.gateway.interface.ipv6}/128"
            ];
            Endpoint = "${intranetCfg.gateways.whitelodge.external.ipv4}:${
                builtins.toString
                intranetCfg.subnets.vpn-isolated.gateway.interface.port
              }";
            PersistentKeepalive = 25;
          };
        }];
      };

      networks."90-${intranetCfg.subnets.l-private.gateway.interface.name}" = {
        matchConfig.Name = intranetCfg.subnets.l-private.gateway.interface.name;

        # Enable IP forwarding (system-wide).
        networkConfig.IPForward = true;

        address = [
          "${intranetCfg.subnets.l-private.gateway.interface.ipv4}/${
            builtins.toString intranetCfg.subnets.vpn-isolated.ipv4.mask
          }"
          "${intranetCfg.subnets.l-private.gateway.interface.ipv6}/${
            builtins.toString intranetCfg.subnets.vpn-isolated.ipv6.mask
          }"
        ];
      };
    };
  };
}
