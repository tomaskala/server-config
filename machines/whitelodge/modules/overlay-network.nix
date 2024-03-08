{ config, lib, pkgs, ... }:

let
  cfg = config.services.overlay-network;
  intranetCfg = config.networking.intranet;

  vpnInterfaceIsolated =
    intranetCfg.subnets.vpn-isolated.gateway.interface.name;

  otherSubnets = builtins.attrValues (lib.filterAttrs
    (_: { gateway, ... }: gateway != null && gateway.name != "whitelodge")
    intranetCfg.subnets);

  maskSubnet = { subnet, mask }: "${subnet}/${builtins.toString mask}";

  makePeer = subnet: {
    wireguardPeerConfig = {
      PublicKey = subnet.gateway.interface.publicKey;
      PresharedKeyFile =
        config.age.secrets."wg-${subnet.gateway.name}2whitelodge".path;
      AllowedIPs = [
        "${subnet.gateway.interface.ipv4}/32"
        "${subnet.gateway.interface.ipv6}/128"
        (maskSubnet subnet.ipv4)
        (maskSubnet subnet.ipv6)
      ];
    };
  };

  makeRoute = subnet: [
    {
      routeConfig = {
        Destination = maskSubnet subnet.ipv4;
        Scope = "link";
        Type = "unicast";
      };
    }
    {
      routeConfig = {
        Destination = maskSubnet subnet.ipv6;
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

      makeAccessibleSet = ipProto: subnet: [
        subnet.gateway.interface.${ipProto}
        (maskSubnet subnet.${ipProto})
      ];

      accessibleIPv4 =
        builtins.concatMap (makeAccessibleSet "ipv4") otherSubnets;

      accessibleIPv6 =
        builtins.concatMap (makeAccessibleSet "ipv6") otherSubnets;
    in ''
      ${lib.concatMapStringsSep "\n" (addToSet "vpn_accessible_ipv4")
      accessibleIPv4}
      ${lib.concatMapStringsSep "\n" (addToSet "vpn_accessible_ipv6")
      accessibleIPv6}
    '';

    # Local DNS records.
    services.unbound.localDomains = let
      allSubnets = builtins.attrValues intranetCfg.subnets;

      allServices = builtins.catAttrs "services" allSubnets;

      flatServices = builtins.concatMap builtins.attrValues allServices;

      urlsToIPs = builtins.map
        ({ url, ipv4, ipv6 }: lib.nameValuePair url { inherit ipv4 ipv6; })
        flatServices;
    in builtins.listToAttrs urlsToIPs;

    systemd.network = {
      enable = true;

      # Add each gateway as a Wireguard peer.
      netdevs."90-${vpnInterfaceIsolated}" = {
        netdevConfig = {
          Name = vpnInterfaceIsolated;
          Kind = "wireguard";
        };

        wireguardConfig = {
          PrivateKeyFile = config.age.secrets.wg-vpn-isolated-pk.path;
          ListenPort = intranetCfg.subnets.vpn-isolated.gateway.interface.port;
        };

        wireguardPeers = builtins.map makePeer otherSubnets;
      };

      networks."90-${vpnInterfaceIsolated}" = {
        matchConfig.Name = vpnInterfaceIsolated;

        # Enable IP forwarding (system-wide).
        networkConfig.IPForward = true;

        address = [
          "${intranetCfg.subnets.vpn-isolated.gateway.interface.ipv4}/${
            builtins.toString intranetCfg.subnets.vpn-isolated.ipv4.mask
          }"
          "${intranetCfg.subnets.vpn-isolated.gateway.interface.ipv6}/${
            builtins.toString intranetCfg.subnets.vpn-isolated.ipv6.mask
          }"
        ];

        # Route traffic to each gateway's network to the Wireguard interface.
        # Wireguard takes care of routing to the correct gateway within the
        # tunnel thanks to the AllowedIPs clause of each gateway peer.
        routes = builtins.concatMap makeRoute otherSubnets;
      };
    };
  };
}
