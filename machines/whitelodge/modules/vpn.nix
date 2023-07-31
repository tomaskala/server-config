{ config, lib, ... }:

let
  cfg = config.services.vpn;
  intranetCfg = config.networking.intranet;
  peerCfg = intranetCfg.peers.whitelodge;
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

        wireguardConfig = {
          PrivateKeyFile = config.age.secrets.wg-pk.path;
          ListenPort = peerCfg.internal.port;
        };

        wireguardPeers = [
          {
            wireguardPeerConfig = {
              # cooper
              PublicKey = "0F/gm1t4hV19N/U/GyB2laclS3CPfGDR2aA3f53EGXk=";
              PresharedKeyFile = config.age.secrets.wg-cooper2whitelodge.path;
              AllowedIPs = [ "10.100.100.1/32" "fd25:6f6:a9f:1100::1/128" ];
            };
          }
          {
            wireguardPeerConfig = {
              # tomas-phone
              PublicKey = "DTJ3VeQGDehQBkYiteIpxtatvgqy2Ux/KjQEmXaEoEQ=";
              PresharedKeyFile =
                config.age.secrets.wg-tomas-phone2whitelodge.path;
              AllowedIPs = [ "10.100.100.2/32" "fd25:6f6:a9f:1100::2/128" ];
            };
          }
          {
            wireguardPeerConfig = {
              # blacklodge
              PublicKey = "b1vNeOy10kbXfldKbaAd5xa2cndgzOE8kQ63HoWXIko=";
              PresharedKeyFile =
                config.age.secrets.wg-blacklodge2whitelodge.path;
              AllowedIPs = [ "10.100.100.3/32" "fd25:6f6:a9f:1100::3/128" ];
            };
          }
          {
            wireguardPeerConfig = {
              # martin-windows
              PublicKey = "JoxRQuYsNZqg/e/DHIVnAsDsA86PjyDlIWPIViMrPUQ=";
              PresharedKeyFile =
                config.age.secrets.wg-martin-windows2whitelodge.path;
              AllowedIPs = [ "10.100.104.1/32" "fd25:6f6:a9f:1200::1/128" ];
            };
          }
        ];
      };

      networks."90-${vpnInterface}" = {
        matchConfig.Name = vpnInterface;

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
