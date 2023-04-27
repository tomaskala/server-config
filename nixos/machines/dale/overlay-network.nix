{ config, pkgs, lib, ... }:

let
  cfg = config.networking.overlay-network;

  makePeer = location: { gateway, subnet }:
    {
      wireguardPeerConfig = {
        PublicKey = gateway.publicKey;
        PresharedKeyFile = config.age.secrets."wg-${location}-psk".path;
        AllowedIPs = [ gateway.ipv4 gateway.ipv6 subnet.ipv4 subnet.ipv6 ];
      };
    };

  makeRoute = subnet:
    [
      {
        Gateway = config.intranet.server.ipv4;
        Destination = subnet.ipv4;
        Scope = "host";
        Type = "local";
      }
      {
        Gateway = config.intranet.server.ipv6;
        Destination = subnet.ipv6;
        Scope = "host";
        Type = "local";
      }
    ];
in
{
  options.networking.overlay-network = {
    enable = lib.mkEnableOption "overlay-network";
  };

  config = lib.mkIf cfg.enable {
    # Firewall entries.
    networking.localCommands =
      let
        addToSet = setName: elem: "${pkgs.nftables}/bin/nft add element inet firewall ${setName} { ${elem} }";

        makeAccessibleSet = ipProto: _: { gateway, subnet }: [ gateway."${ipProto}" subnet."${ipProto}" ];

        accessibleIPv4 = builtins.mapAttrs (makeAccessibleSet "ipv4") config.intranet.locations;

        accessibleIPv6 = builtins.mapAttrs (makeAccessibleSet "ipv6") config.intranet.locations;
      in
      ''
        ${addToSet "vpn_internal_ipv4" (config.maskedSubnet config.intranet.subnets.internal.ipv4)}
        ${addToSet "vpn_internal_ipv6" (config.maskedSubnet config.intranet.subnets.internal.ipv6)}

        ${addToSet "vpn_isolated_ipv4" (config.maskedSubnet config.intranet.subnets.isolated.ipv4)}
        ${addToSet "vpn_isolated_ipv6" (config.maskedSubnet config.intranet.subnets.isolated.ipv6)}

        ${lib.concatMapStringsSep "\n" (addToSet "vpn_accessible_ipv4") accessibleIPv4}
        ${lib.concatMapStringsSep "\n" (addToSet "vpn_accessible_ipv6") accessibleIPv6}
      '';

    # Local DNS records.
    services.unbound.localDomains = config.intranet.localDomains;

    systemd.network = {
      # Add each location's gateway as a Wireguard peer.
      netdevs."90-${config.intranet.server.interface}" = {
        wireguardPeers = builtins.attrValues (builtins.mapAttrs makePeer config.intranet.locations);
      };

      networks."90-${config.intranet.server.interface}" = {
        # IP forwarding.
        networkConfig = {
          IPForward = true;
        };

        # Route traffic to each location's subnet to the Wireguard interface.
        # Wireguard takes care of routing to the correct gateway within the
        # tunnel thanks to the AllowedIPs clause of each gateway peer.
        routes =
          let
            locationValues = builtins.attrValues config.intranet.locations;

            subnets = builtins.catAttrs "subnet" locationValues;
          in
          builtins.concatMap makeRoute subnets;
      };
    };
  };
}
