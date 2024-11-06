{ config, pkgs, ... }:

let
  inherit (pkgs) infra;

  intranetCfg = config.infra.intranet;
  deviceCfg = intranetCfg.devices.cooper;
  serverCfg = intranetCfg.devices.whitelodge;

  serverIPv4 = infra.ipAddress serverCfg.wireguard.internal.ipv4;
  serverIPv6 = infra.ipAddress serverCfg.wireguard.internal.ipv6;

  wgInterfaceCfg = {
    privateKeyFile = config.age.secrets.wg-cooper-internal-pk.path;
    address = [
      (infra.ipAddressMasked deviceCfg.wireguard.internal.ipv4
        intranetCfg.wireguard.internal.ipv4.mask)
      (infra.ipAddressMasked deviceCfg.wireguard.internal.ipv6
        intranetCfg.wireguard.internal.ipv6.mask)
    ];
  };

  wgDnsCfg = {
    dns = [ serverIPv4 serverIPv6 ];
    postUp = ''
      ${pkgs.systemd}/bin/resolvectl dns %i ${serverIPv4} ${serverIPv6}
      ${pkgs.systemd}/bin/resolvectl domain %i "~."
      ${pkgs.systemd}/bin/resolvectl default-route %i true
    '';
    preDown = ''
      ${pkgs.systemd}/bin/resolvectl revert %i
    '';
  };

  peerCommonCfg = {
    inherit (serverCfg.wireguard.internal) publicKey;
    presharedKeyFile = config.age.secrets.wg-cooper2whitelodge.path;
    endpoint = "${serverCfg.external.wan.ipv4}:${
        builtins.toString serverCfg.wireguard.internal.port
      }";
  };
in {
  networking.wg-quick.interfaces = {
    wg-access = wgInterfaceCfg // {
      autostart = false;
      peers =
        [ (peerCommonCfg // { allowedIPs = [ serverIPv4 serverIPv6 ]; }) ];
    };

    wg-intranet = wgInterfaceCfg // wgDnsCfg // {
      autostart = false;
      peers = [
        (peerCommonCfg // {
          allowedIPs = [
            (infra.ipSubnet intranetCfg.wireguard.internal.ipv4)
            (infra.ipSubnet intranetCfg.wireguard.internal.ipv6)
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
