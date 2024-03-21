{ config, lib, util, ... }:

let
  cfg = config.services.vpn;
  intranetCfg = config.networking.intranet;
  deviceCfg = intranetCfg.devices.whitelodge;

  mkPeer = { interface, presharedKeyFile }:
    let inherit (interface) publicKey subnet ipv4 ipv6;
    in {
      wireguardPeerConfig = {
        PublicKey = publicKey;

        PresharedKeyFile = presharedKeyFile;

        AllowedIPs =
          [ (util.ipAddressMasked ipv4 32) (util.ipAddressMasked ipv6 128) ]
          ++ lib.optionals (subnet != null) [
            (util.ipSubnet subnet.ipv4)
            (util.ipSubnet subnet.ipv6)
          ];
      };
    };

  mkRoute = { ipv4, ipv6, ... }: [
    {
      routeConfig = {
        Destination = util.ipSubnet ipv4;
        Scope = "link";
        Type = "unicast";
      };
    }
    {
      routeConfig = {
        Destination = util.ipSubnet ipv6;
        Scope = "link";
        Type = "unicast";
      };
    }
  ];

  mkLocalDomains = let
    mkLocalDomain = _:
      { url, ipv4, ipv6 }:
      lib.nameValuePair url {
        ipv4 = util.ipAddress ipv4;
        ipv6 = util.ipAddress ipv6;
      };
  in { services, ... }: lib.mapAttrs' mkLocalDomain services;

  mkSubnet = interface: subnet:
    let
      inherit (interface) name privateKeyFile port ipv4 ipv6;

      accessibleSubnets = let
        deviceSubnets =
          builtins.map ({ interface, ... }: interface.subnet) subnet.devices;
      in builtins.filter (subnet: subnet != null) deviceSubnets;
    in {
      systemd.network = {
        enable = true;

        netdevs."90-${name}" = {
          netdevConfig = {
            Name = name;
            Kind = "wireguard";
          };

          wireguardConfig = {
            PrivateKeyFile = assert privateKeyFile != null; privateKeyFile;
            ListenPort = port;
          };

          wireguardPeers = builtins.map mkPeer subnet.devices;
        };

        networks."90-${name}" = {
          matchConfig.Name = name;

          networkConfig.IPForward = true;

          address = [
            (util.ipAddressMasked ipv4 subnet.ipv4.mask)
            (util.ipAddressMasked ipv6 subnet.ipv6.mask)
          ];

          routes = builtins.concatMap mkRoute accessibleSubnets;
        };
      };

      services.unbound.localDomains = lib.attrsets.mergeAttrsList
        (builtins.map mkLocalDomains ([ subnet ] ++ accessibleSubnets));
    };
in {
  options.services.vpn = {
    enable = lib.mkEnableOption "vpn";

    enableInternal = lib.mkEnableOption "internal subnet";

    enableIsolated = lib.mkEnableOption "isolated subnet";

    enablePassthru = lib.mkEnableOption "passthru subnet";
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    (lib.mkIf cfg.enableInternal
      (mkSubnet deviceCfg.wireguard.internal intranetCfg.vpn.internal))

    (lib.mkIf cfg.enableIsolated
      (mkSubnet deviceCfg.wireguard.isolated intranetCfg.vpn.isolated))

    (lib.mkIf cfg.enablePassthru
      (mkSubnet deviceCfg.wireguard.passthru intranetCfg.vpn.passthru))
  ]);
}
