{ config, lib, ... }:

let
  cfg = config.services.monitoring;
  intranetCfg = config.networking.intranet;
  inherit (config.networking) hostName;
  peerCfg = intranetCfg.peers.${hostName};
in {
  options.services.monitoring = { enable = lib.mkEnableOption "monitoring"; };

  config = lib.mkIf cfg.enable {
    services.prometheus.exporters = builtins.mapAttrs (_: port: {
      enable = true;
      openFirewall = false;
      listenAddress = peerCfg.internal.interface.ipv4;
      inherit port;
    }) peerCfg.exporters;
  };
}
