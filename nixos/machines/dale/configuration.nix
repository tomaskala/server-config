{ config, pkgs, ... }:

# TODO: Make per-host values such as listening addresses configurable.
# This should be done by making each service accept an option with that
# address and configuring those.

# TODO: Enable services here, not in their definition files (like nginx is
# but openssh and unbound aren't).

# TODO: Make each service's configuration stand-alone? Meaning that the
# RSS configuration file will configure the RSS reader as well as setup
# nginx reverse proxy.

{
  imports = [
    ./constants.nix
    ../common.nix
    ../services/nginx.nix
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

  users.users.git = {
    isSystemUser = true;
    createHome = true;
    home = "/home/git";
    shell = "${pkgs.git}/bin/git-shell";
    group = "git";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBaTcR5f4bbzG6JmuyFfMAEuQYRmWzt518BlBIbyr1MK laptop2dale-git"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOCmYsyCuOmqW1utcZvBWYIzZnDEXUjmg/YpdcOWudF5 phone2dale-git"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDQQQ7zAwXCpFVWNGnhOck8GqOELWAHCy5NrH9nyxjzU home2dale-git"
    ];
  };

  time.timezone = "Europe/Prague";

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

  services.nginx = {
    enable = true;
    publicSites = {
      ${config.domain} = {
        root = "/var/www/${config.domain}";

        locations."/" = {
          index = "index.html";

          extraOptions = ''
            # Remove the .html suffix.
            if ($request_uri ~ ^/(.*)\.html) {
                return 301 /$1$is_args$args;
            }
            try_files $uri $uri.html $uri/ =404;
          '';
        }

        extraConfig = ''
          # Prevent image hotlinking.
          location ~ \.(gif|png|jpg|jpeg|ico)$ {
              valid_referers none blocked {{ domain }};
              if ($invalid_referer) {
                  return 403;
              }
          }
        '';
      };
    };
  }

  # TODO
  # * wireguard
  #   * when configuring the system for the first time, manually generate
  #     the server keys and the primary client's preshared key to the files
  #     specified by the wireguard config. only then switch to the config
  # * wireguard client
  # * unbound blocking
  # * overlay network
  # * tls certificate
  # * rss

  # TODO: https://nixos.org/manual/nixos/stable/index.html#module-security-acme
}
