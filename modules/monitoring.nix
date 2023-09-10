{ config, lib, ... }:

let
  cfg = config.services.monitoring;
  intranetCfg = config.networking.intranet;
  gatewayCfg = intranetCfg.gateways.${config.networking.hostName};
in {
  options.services.monitoring = { enable = lib.mkEnableOption "monitoring"; };

  config = lib.mkIf cfg.enable {
    services.prometheus.exporters = builtins.mapAttrs (_: exporter:
      {
        enable = true;
        openFirewall = false;
        listenAddress = gatewayCfg.internal.interface.ipv4;
      } // exporter) gatewayCfg.exporters;
  };
}
