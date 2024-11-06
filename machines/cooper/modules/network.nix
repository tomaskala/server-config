{
  networking.networkmanager = {
    enable = true;
    wifi.backend = "iwd";
  };

  services.avahi = {
    enable = true;
    openFirewall = true;
  };
}
