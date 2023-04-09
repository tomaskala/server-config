{ config, pkgs, ... }:

# TODO: Make each service's configuration stand-alone? Meaning that the
# RSS configuration file will configure the RSS reader as well as setup
# nginx reverse proxy.

{
  imports = [
    ./constants.nix
    ./acme.nix
    ../common.nix
    ../services/nginx.nix
    ../services/openssh.nix
    ../services/unbound.nix
    ../services/yarr.nix
  ];

  config = {
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
    services.ntp.enable = false;
    services.timesyncd.enable = true;

    programs.vim.defaultEditor = true;
    environment.systemPackages = with pkgs; [
      git
      rsync
      tmux
    ];

    networking.hostName = "dale";
    networking.firewall.enable = false;
    networking.nftables = {
      enabled = true;
      rulesetFile = import ./nftables-ruleset.nix { inherit config pkgs; };
    };

    services.openssh = {
      enable = true;
      listenAddresses = [
        { addr = config.intranet.server.ipv4; port = 22; }
        { addr = config.intranet.server.ipv6; port = 22; }
      ];
    };

    services.unbound = {
      enable = true;
      localDomains = [
        { domain = config.domains.public;
          ipv4 = config.intranet.server.ipv4;
          ipv6 = config.intranet.server.ipv6;
        }
        { domain = config.domains.rss;
          ipv4 = config.intranet.server.ipv4;
          ipv6 = config.intranet.server.ipv6;
        }
      ];
    };

    services.nginx = {
      enable = true;
      virtualHosts.${config.domains.public} = {
        root = "/var/www/${config.domains.public}";
        forceSSL = true;
        enableACME = true;

        locations."/" = {
          index = "index.html";

          extraConfig = ''
            # Remove the .html suffix.
            if ($request_uri ~ ^/(.*)\.html) {
              return 301 /$1$is_args$args;
            }
            try_files $uri $uri.html $uri/ =404;
          '';
        };

        extraConfig = ''
          # Add HSTS header with preloading to HTTPS requests.
          # Adding this header to HTTP requests is discouraged.
          map $scheme $hsts_header {
            https "max-age=31536000; includeSubdomains; preload";
          }
          add_header Strict-Transport-Security $hsts_header;

          # Enable CSP for your services.
          add_header Content-Security-Policy "script-src 'self'; object-src 'none'; base-uri 'none';" always;

          # Minimize information leaked to other domains.
          add_header 'Referrer-Policy' 'origin-when-cross-origin';

          # Disable embedding as a frame.
          add_header X-Frame-Options DENY;

          # Prevent injection of code in other mime types (XSS Attacks).
          add_header X-Content-Type-Options nosniff;

          # Enable XSS protection of the browser.
          add_header X-XSS-Protection "1; mode=block";

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

    services.yarr = {
      enable = true;
      listenPort = 7070;
      workingDirectory = "/var/yarr";
    };

    # TODO
    # * wireguard
    #   * when configuring the system for the first time, manually generate
    #     the server keys and the primary client's preshared key to the files
    #     specified by the wireguard config. only then switch to the config
    # * wireguard client
    # * unbound blocking
    # * overlay network
  };
}
