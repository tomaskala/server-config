{ config, pkgs, ... }:

let
  intranetCfg = config.networking.intranet;
  deviceCfg = intranetCfg.devices.cooper;

  vpnSubnet = intranetCfg.subnets.vpn;
  whitelodgeIPv4 = intranetCfg.gateways.whitelodge.internal.interface.ipv4;
  whitelodgeIPv6 = intranetCfg.gateways.whitelodge.internal.interface.ipv6;

  wgInterfaceCfg = {
    privateKeyFile = config.age.secrets.wg-pk.path;
    address = [
      "${deviceCfg.interface.ipv4}/${builtins.toString vpnSubnet.ipv4.mask}"
      "${deviceCfg.interface.ipv6}/${builtins.toString vpnSubnet.ipv6.mask}"
    ];
  };

  wgDnsCfg = {
    dns = [ whitelodgeIPv4 whitelodgeIPv6 ];
    postUp = ''
      ${pkgs.systemd}/bin/resolvectl dns %i ${whitelodgeIPv4} ${whitelodgeIPv6}
      ${pkgs.systemd}/bin/resolvectl domain %i "~."
      ${pkgs.systemd}/bin/resolvectl default-route %i true
    '';
    preDown = ''
      ${pkgs.systemd}/bin/resolvectl revert %i
    '';
  };

  peerCommonCfg = {
    publicKey = intranetCfg.gateways.whitelodge.internal.publicKey;
    presharedKeyFile = config.age.secrets.wg-cooper2whitelodge.path;
    endpoint = "${intranetCfg.gateways.whitelodge.external.ipv4}:${
        builtins.toString intranetCfg.gateways.whitelodge.internal.port
      }";
  };
in {
  networking.wg-quick.interfaces = {
    wg-access = wgInterfaceCfg // {
      autostart = false;
      peers = [
        (peerCommonCfg // { allowedIPs = [ whitelodgeIPv4 whitelodgeIPv6 ]; })
      ];
    };

    wg-intranet = wgInterfaceCfg // wgDnsCfg // {
      autostart = true;
      peers = [
        (peerCommonCfg // {
          allowedIPs = [
            intranetCfg.subnets.intranet.ipv4
            intranetCfg.subnets.intranet.ipv6
          ];
        })
      ];
    };

    wg-full = wgInterfaceCfg // wgDnsCfg // {
      autostart = false;
      peers = [ (peerCommonCfg // { allowedIPs = [ "0.0.0.0/0" "::/0" ]; }) ];
    };
  };
}
