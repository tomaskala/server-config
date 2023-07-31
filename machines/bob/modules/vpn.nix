{ config, lib, ... }:

let
  cfg = config.services.vpn;
  intranetCfg = config.networking.intranet;
  peerCfg = intranetCfg.peers.bob;

  vpnInterface = peerCfg.internal.interface.name;
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
            PublicKey = intranetCfg.peers.whitelodge.internal.publicKey;
            PresharedKeyFile = config.age.secrets.wg-bob2whitelodge.path;
            AllowedIPs = [
              "${intranetCfg.peers.whitelodge.internal.interface.ipv4}/32"
              "${intranetCfg.peers.whitelodge.internal.interface.ipv6}/128"
            ];
            Endpoint = "${intranetCfg.peers.whitelodge.external.ipv4}:${
                builtins.toString intranetCfg.peers.whitelodge.internal.port
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
          "${peerCfg.internal.interface.ipv4}/${
            builtins.toString vpnSubnet.ipv4.mask
          }"
          "${peerCfg.internal.interface.ipv6}/${
            builtins.toString vpnSubnet.ipv6.mask
          }"
        ];
      };
    };

  };
}
