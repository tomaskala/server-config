{ config, pkgs, util, ... }:

let
  intranetCfg = config.infra.intranet;
  privateSubnet = intranetCfg.subnets.l-internal;
in {
  services.printing = {
    enable = true;
    drivers = [ pkgs.hplip ];
    startWhenNeeded = true;

    listenAddresses = [ "localhost:631" ];
    allowFrom = [ "localhost" ];

    stateless = true;
    browsing = false;
  };

  hardware.printers = {
    ensureDefaultPrinter = "HP@l";
    ensurePrinters = [{
      name = "HP@l";
      location = "l";
      description = "HP_OfficeJet_Pro_8715";
      deviceUri =
        "ipp://${util.ipAddress privateSubnet.services.printer.ipv4}/ipp/print";
      model = "lsb/usr/HP/hp-officejet_pro_8710.ppd.gz";
      ppdOptions = { PageSize = "A4"; };
    }];
  };
}
