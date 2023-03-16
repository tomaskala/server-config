{ config, ... }:

{
  services.openssh = {
    enable = true;
    listenAddresses = [
      { addr = config.intranet.server.ipv4; port = 22; }
      { addr = config.intranet.server.ipv6; port = 22; }
    ];
    openFirewall = false;
    passwordAuthentication = false;
    permitRootLogin = false;
    forwardX11 = false;
    gatewayPorts = false;
  };
}
