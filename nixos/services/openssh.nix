{
  config.services.openssh = {
    openFirewall = false;
    passwordAuthentication = false;
    permitRootLogin = false;
    forwardX11 = false;
    gatewayPorts = false;
  };
}
