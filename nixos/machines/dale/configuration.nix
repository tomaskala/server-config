{ config, pkgs, ... }:

# TODO: Make per-host values such as listening addresses configurable.
# This should be done by making each service accept an option with that
# address and configuring those.
{
  imports = [
    ../common.nix
    ../services/openssh.nix
    ../services/unbound.nix
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
  wanInterface = "venet0";  # TODO: Should this be here?

  environment.systemPackages = with pkgs; [
    git
    rsync
    tmux
    vim
  ];

  networking.hostName = "dale";
  networking.firewall.enable = false;
  networking.nftables = {
    enabled = true;
    rulesetFile = ./nftables-ruleset.nix { inherit config pkgs; };
  };

  # TODO
  # * wireguard
  # * wireguard client
  # * unbound blocking
  # * overlay network
  # * nginx
  # * tls certificate
  # * website
  # * git
  # * rss

  # TODO: https://nixos.org/manual/nixos/stable/index.html#module-security-acme
}
