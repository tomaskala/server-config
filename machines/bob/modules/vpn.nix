{ config, lib, util, ... }:

let
  cfg = config.services.vpn;
  intranetCfg = config.networking.intranet;
  deviceCfg = intranetCfg.devices.bob;
in {
  options.services.vpn = { enable = lib.mkEnableOption "vpn"; };

  config = lib.mkIf cfg.enable {
    systemd.network = {
      enable = true;

      netdevs."90-${deviceCfg.wireguard.isolated.name}" = {
        netdevConfig = {
          Name = deviceCfg.wireguard.isolated.name;
          Kind = "wireguard";
        };

        wireguardConfig = { PrivateKeyFile = config.age.secrets.wg-pk.path; };

        wireguardPeers = [{
          wireguardPeerConfig = {
            PublicKey =
              intranetCfg.devices.whitelodge.wireguard.isolated.publicKey;
            PresharedKeyFile = config.age.secrets.wg-bob2whitelodge.path;
            AllowedIPs = [
              (util.ipAddressMasked
                intranetCfg.devices.whitelodge.wireguard.isolated.ipv4 32)
              (util.ipAddressMasked
                intranetCfg.devices.whitelodge.wireguard.isolated.ipv6 128)
            ];
            Endpoint = "${intranetCfg.devices.whitelodge.external.wan.ipv4}:${
                builtins.toString
                intranetCfg.devices.whitelodge.wireguard.isolated.port
              }";
            PersistentKeepalive = 25;
          };
        }];
      };

      networks."90-${deviceCfg.wireguard.isolated.name}" = {
        matchConfig.Name = deviceCfg.wireguard.isolated.name;

        # Enable IP forwarding (system-wide).
        networkConfig.IPForward = true;

        address = [
          (util.ipAddressMasked deviceCfg.wireguard.isolated.ipv4
            intranetCfg.vpn.isolated.ipv4.mask)
          (util.ipAddressMasked deviceCfg.wireguard.isolated.ipv6
            intranetCfg.vpn.isolated.ipv6.mask)
        ];
      };
    };
  };
}
