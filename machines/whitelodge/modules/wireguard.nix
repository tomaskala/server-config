{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (pkgs) infra;

  cfg = config.infra.wireguard;
  intranetCfg = config.infra.intranet;
  deviceCfg = intranetCfg.devices.whitelodge;

  mkPeer =
    { interface, presharedKeyFile }:
    let
      inherit (interface)
        publicKey
        subnet
        ipv4
        ipv6
        ;
    in
    {
      PublicKey = publicKey;
      PresharedKeyFile = presharedKeyFile;
      AllowedIPs =
        [
          (infra.ipAddressMasked ipv4 32)
          (infra.ipAddressMasked ipv6 128)
        ]
        ++ lib.optionals (subnet != null) [
          (infra.ipSubnet subnet.ipv4)
          (infra.ipSubnet subnet.ipv6)
        ];
    };

  mkRoute =
    { ipv4, ipv6, ... }:
    [
      {
        Destination = infra.ipSubnet ipv4;
        Scope = "link";
        Type = "unicast";
      }
      {
        Destination = infra.ipSubnet ipv6;
        Scope = "link";
        Type = "unicast";
      }
    ];

  mkLocalDomains =
    let
      mkLocalDomain =
        _:
        {
          url,
          ipv4,
          ipv6,
        }:
        lib.nameValuePair url { inherit ipv4 ipv6; };
    in
    { services, ... }:
    lib.mapAttrs' mkLocalDomain services;

  mkSubnet =
    interface: subnet:
    let
      inherit (interface)
        name
        privateKeyFile
        port
        ipv4
        ipv6
        ;

      accessibleSubnets =
        let
          deviceSubnets = builtins.map ({ interface, ... }: interface.subnet) subnet.devices;
        in
        builtins.filter (subnet: subnet != null) deviceSubnets;
    in
    {
      systemd.network = {
        enable = true;

        netdevs."90-${name}" = {
          netdevConfig = {
            Name = name;
            Kind = "wireguard";
          };

          wireguardConfig = {
            PrivateKeyFile =
              assert privateKeyFile != null;
              privateKeyFile;
            ListenPort = port;
          };

          wireguardPeers = builtins.map mkPeer subnet.devices;
        };

        networks."90-${name}" = {
          matchConfig.Name = name;

          networkConfig = {
            IPv4Forwarding = true;
            IPv6Forwarding = true;
          };

          address = [
            (infra.ipAddressMasked ipv4 subnet.ipv4.mask)
            (infra.ipAddressMasked ipv6 subnet.ipv6.mask)
          ];

          routes = builtins.concatMap mkRoute accessibleSubnets;
        };
      };

      infra.blocky.localDomains = lib.attrsets.mergeAttrsList (
        builtins.map mkLocalDomains ([ subnet ] ++ accessibleSubnets)
      );
    };
in
{
  options.infra.wireguard = {
    enable = lib.mkEnableOption "wireguard";

    enableInternal = lib.mkEnableOption "internal subnet";

    enableIsolated = lib.mkEnableOption "isolated subnet";

    enablePassthru = lib.mkEnableOption "passthru subnet";
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      (lib.mkIf cfg.enableInternal (mkSubnet deviceCfg.wireguard.internal intranetCfg.wireguard.internal))

      (lib.mkIf cfg.enableIsolated (mkSubnet deviceCfg.wireguard.isolated intranetCfg.wireguard.isolated))

      (lib.mkIf cfg.enablePassthru (mkSubnet deviceCfg.wireguard.passthru intranetCfg.wireguard.passthru))
    ]
  );
}
