{ config, pkgs, ... }:

{
  imports = [
    ../common.nix
  ];

  users.users.tomas = {
    isNormalUser = true;
    home = "/home/tomas";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPrK/gGoC5nX+u82z2N/8u+gd/yMJrb6pMln/zJJjG4w laptop2dale"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDXh5D6Rhl/ORiXXW+BYZN3+/OcyMdPKTI+BM7HQI8MN home2dale"
    ];
  };

  time.timezone = "Europe/Prague";
  wanInterface = "venet0";

  environment.systemPackages = with pkgs; [
    git
    rsync
    tmux
    vim
  ];

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

  networking.hostName = "dale";
  networking.firewall.enable = false;
  networking.nftables = {
    enabled = true;
    rulesetFile = ./nftables-ruleset.nix { inherit config pkgs; };
  };

  # TODO: https://nixos.org/manual/nixos/stable/index.html#module-security-acme
}
