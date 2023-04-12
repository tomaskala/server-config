{ config, lib, ... }:

let
  cfg = config.networking.intranet;

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
  options.networking.intranet = {
    enable = lib.mkEnableOption "intranet";
  };

  config.networking.intranet = lib.mkIf cfg.enable {
    # TODO: Firewall entries; networking.localCommands may be useful here.

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
