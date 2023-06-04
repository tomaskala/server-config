{
  config.services.openssh = {
    openFirewall = false;

    settings = {
      X11Forwarding = false;
      GatewayPorts = "no";
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };
}
