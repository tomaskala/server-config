{ config, lib, pkgs, ... }:

let
  cfg = config.services.overlay-network;
  intranetCfg = config.networking.intranet;
  gatewayCfg = intranetCfg.gateways.whitelodge;

  vpnInterface = gatewayCfg.internal.interface.name;
  otherGateways = lib.filterAttrs (gatewayName: _: gatewayName != "whitelodge")
    intranetCfg.gateways;

  vpnSubnet = intranetCfg.subnets.vpn;
  maskSubnet = { subnet, mask }: "${subnet}/${builtins.toString mask}";

  makePeer = peerName:
    { internal, network, ... }: {
      wireguardPeerConfig = {
        PublicKey = internal.publicKey;
        PresharedKeyFile = config.age.secrets."wg-${peerName}2whitelodge".path;
        AllowedIPs = [
          "${internal.interface.ipv4}/32"
          "${internal.interface.ipv6}/128"
          (maskSubnet intranetCfg.subnets.${network}.ipv4)
          (maskSubnet intranetCfg.subnets.${network}.ipv6)
        ];
      };
    };

  makeRoute = network: [
    {
      routeConfig = {
        Destination = maskSubnet intranetCfg.subnets.${network}.ipv4;
        Scope = "link";
        Type = "unicast";
      };
    }
    {
      routeConfig = {
        Destination = maskSubnet intranetCfg.subnets.${network}.ipv6;
        Scope = "link";
        Type = "unicast";
      };
    }
  ];
in {
  options.services.overlay-network = {
    enable = lib.mkEnableOption "overlay-network";
  };

  config = lib.mkIf cfg.enable {
    # Firewall entries.
    networking.localCommands = let
      addToSet = setName: elem:
        "${pkgs.nftables}/bin/nft add element inet firewall ${setName} { ${elem} }";

      makeAccessibleSet = ipProto:
        { internal, network, ... }: [
          internal.interface.${ipProto}
          (maskSubnet intranetCfg.subnets.${network}.${ipProto})
        ];

      accessibleIPv4 = builtins.concatMap (makeAccessibleSet "ipv4")
        (builtins.attrValues otherGateways);

      accessibleIPv6 = builtins.concatMap (makeAccessibleSet "ipv6")
        (builtins.attrValues otherGateways);
    in ''
      ${addToSet "vpn_internal_ipv4"
      (maskSubnet intranetCfg.subnets.vpn-internal.ipv4)}
      ${addToSet "vpn_internal_ipv6"
      (maskSubnet intranetCfg.subnets.vpn-internal.ipv6)}

      ${addToSet "vpn_isolated_ipv4"
      (maskSubnet intranetCfg.subnets.vpn-isolated.ipv4)}
      ${addToSet "vpn_isolated_ipv6"
      (maskSubnet intranetCfg.subnets.vpn-isolated.ipv6)}

      ${lib.concatMapStringsSep "\n" (addToSet "vpn_accessible_ipv4")
      accessibleIPv4}
      ${lib.concatMapStringsSep "\n" (addToSet "vpn_accessible_ipv6")
      accessibleIPv6}
    '';

    # Local DNS records.
    services.unbound.localDomains = lib.mapAttrs' (_:
      { url, ipv4, ipv6 }: {
        name = url;
        value = { inherit ipv4 ipv6; };
      }) intranetCfg.services;

    systemd.network = {
      enable = true;

      # Add each gateway as a Wireguard peer.
      netdevs."90-${vpnInterface}" = {
        netdevConfig = {
          Name = vpnInterface;
          Kind = "wireguard";
        };

        wireguardConfig = {
          PrivateKeyFile = config.age.secrets.wg-pk.path;
          ListenPort = gatewayCfg.internal.port;
        };

        wireguardPeers = lib.mapAttrsToList makePeer otherGateways;
      };

      networks."90-${vpnInterface}" = {
        matchConfig.Name = vpnInterface;

        # Enable IP forwarding (system-wide).
        networkConfig.IPForward = true;

        address = [
          "${gatewayCfg.internal.interface.ipv4}/${
            builtins.toString vpnSubnet.ipv4.mask
          }"
          "${gatewayCfg.internal.interface.ipv6}/${
            builtins.toString vpnSubnet.ipv6.mask
          }"
        ];

        # Route traffic to each gateway's network to the Wireguard interface.
        # Wireguard takes care of routing to the correct gateway within the
        # tunnel thanks to the AllowedIPs clause of each gateway peer.
        routes = let
          gatewayValues = builtins.attrValues otherGateways;

          networks = builtins.catAttrs "network" gatewayValues;
        in builtins.concatMap makeRoute networks;
      };
    };
  };
}
