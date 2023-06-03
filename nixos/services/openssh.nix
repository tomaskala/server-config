{
  config.services.openssh = {
    openFirewall = false;
    passwordAuthentication = false;
    permitRootLogin = "no";
    forwardX11 = false;
    gatewayPorts = "no";
  };
}
