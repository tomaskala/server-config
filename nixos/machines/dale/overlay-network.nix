{ config, pkgs, lib, ... }:

let
  cfg = config.networking.overlay-network;
  intranetCfg = config.networking.intranet;

  maskSubnet = { subnet, mask }: "${subnet}/${builtins.toString mask}";

  makePeer = location:
    { gateway, subnet }: {
      wireguardPeerConfig = {
        PublicKey = gateway.publicKey;
        PresharedKeyFile = config.age.secrets."wg-${location}-psk".path;
        AllowedIPs = [
          gateway.ipv4
          gateway.ipv6
          (maskSubnet subnet.ipv4)
          (maskSubnet subnet.ipv6)
        ];
      };
    };

  makeRoute = subnet: [
    {
      routeConfig = {
        Destination = maskSubnet subnet.ipv4;
        Scope = "host";
        Type = "local";
      };
    }
    {
      routeConfig = {
        Destination = maskSubnet subnet.ipv6;
        Scope = "host";
        Type = "local";
      };
    }
  ];
in {
  options.networking.overlay-network = {
    enable = lib.mkEnableOption "overlay-network";
  };

  config = lib.mkIf cfg.enable {
    # Firewall entries.
    networking.localCommands = let
      addToSet = setName: elem:
        "${pkgs.nftables}/bin/nft add element inet firewall ${setName} { ${elem} }";

      makeAccessibleSet = ipProto:
        { gateway, subnet }: [
          gateway."${ipProto}"
          (maskSubnet subnet."${ipProto}")
        ];

      accessibleIPv4 = builtins.concatMap (makeAccessibleSet "ipv4")
        (builtins.attrValues intranetCfg.locations);

      accessibleIPv6 = builtins.concatMap (makeAccessibleSet "ipv6")
        (builtins.attrValues intranetCfg.locations);
    in ''
      ${addToSet "vpn_internal_ipv4"
      (maskSubnet intranetCfg.subnets.internal.ipv4)}
      ${addToSet "vpn_internal_ipv6"
      (maskSubnet intranetCfg.subnets.internal.ipv6)}

      ${addToSet "vpn_isolated_ipv4"
      (maskSubnet intranetCfg.subnets.isolated.ipv4)}
      ${addToSet "vpn_isolated_ipv6"
      (maskSubnet intranetCfg.subnets.isolated.ipv6)}

      ${lib.concatMapStringsSep "\n" (addToSet "vpn_accessible_ipv4")
      accessibleIPv4}
      ${lib.concatMapStringsSep "\n" (addToSet "vpn_accessible_ipv6")
      accessibleIPv6}
    '';

    # Local DNS records.
    services.unbound.localDomains = intranetCfg.localDomains;

    systemd.network = {
      enable = true;

      # Add each location's gateway as a Wireguard peer.
      netdevs."90-${intranetCfg.server.interface}" = {
        wireguardPeers = lib.mapAttrsToList makePeer intranetCfg.locations;
      };

      networks."90-${intranetCfg.server.interface}" = {
        # IP forwarding.
        networkConfig = { IPForward = true; };

        # Route traffic to each location's subnet to the Wireguard interface.
        # Wireguard takes care of routing to the correct gateway within the
        # tunnel thanks to the AllowedIPs clause of each gateway peer.
        routes = let
          locationValues = builtins.attrValues intranetCfg.locations;

          subnets = builtins.catAttrs "subnet" locationValues;
        in builtins.concatMap makeRoute subnets;
      };
    };
  };
}
