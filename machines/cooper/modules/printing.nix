{ config, pkgs, ... }:

let
  intranetCfg = config.networking.intranet;
  privateSubnet = intranetCfg.subnets.home-private;
in {
  services.printing = {
    enable = true;
    drivers = with pkgs; [ hplip ];
    startWhenNeeded = true;

    listenAddresses = [ "localhost:631" ];
    allowFrom = [ "localhost" ];

    stateless = true;
    browsing = false;
  };

  hardware.printers = {
    ensureDefaultPrinter = "HP_home";
    ensurePrinters = [{
      name = "HP_home";
      location = "home";
      description = "HP_OfficeJet_Pro_8715";
      deviceUri = "ipp://${privateSubnet.services.printer.ipv4}/ipp/print";
      model = "lsb/usr/HP/hp-officejet_pro_8710.ppd.gz";
      ppdOptions = { PageSize = "A4"; };
    }];
  };
}
