{ config, lib, ... }:

let
  cfg = config.services.vpn;
  intranetCfg = config.networking.intranet;

  mkPeer = { name, publicKey, interface, ... }: {
    wireguardPeerConfig = {
      PublicKey = publicKey;
      PresharedKeyFile = config.age.secrets."wg-${name}2whitelodge".path;
      AllowedIPs = [ "${interface.ipv4}/32" "${interface.ipv6}/32" ];
    };
  };
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

          wireguardPeers = builtins.map mkPeer intranetCfg.devices;
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
