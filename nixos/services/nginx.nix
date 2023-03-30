{ config, pkgs, lib, ... }:

let
  cfg = config.services.nginx;

  commonPublicConfig = ''
    # Add HSTS header with preloading to HTTPS requests.
    # Adding this header to HTTP requests is discouraged.
    map $scheme $hsts_header {
        https   "max-age=31536000; includeSubdomains; preload";
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
  '';

  commonPrivateConfig = ''
    allow 127.0.0.1;
    allow ::1;
    deny all;
  '';
in {
  options.services.nginx = {
    publicSites = lib.mkOption {
      default = { };
      type = pkgs.nginx.virtualHosts.type;
      description = ''
        One virtual host configuration block per public-facing domain.
      '';
      example = pkgs.nginx.virtualHosts.example;
    };

    privateSites = lib.mkOption {
      default = { };
      type = pkgs.nginx.virtualHosts.type;
      description = ''
        One virtual host configuration block per private domain.
      '';
      example = pkgs.nginx.virtualHosts.example;
    };
  };

  config.services.nginx = {
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    # Only allow PFS-enabled ciphers with AES256.
    sslCiphers = "AES256+EECDH:AES256+EDH:!aNULL";

    commonHttpConfig = ''
      # Disable directory listing.
      autoindex off;

      # Do not emit the nginx version on error pages.
      server_tokens off;
    '';

    virtualHosts = let
      mkPublic = _: vhostConfig@{ extraConfig ? "", ... }:
        vhostConfig // {
          forceSSL = true;
          enableACME = true;
          extraConfig = concatStringsSep "\n" [ extraConfig commonPublicConfig ];
        };
      mkPrivate = _: vhostConfig@{ extraConfig ? "", ... }:
        vhostConfig // {
          extraConfig = concatStringsSep "\n" [ extraConfig commonPrivateConfig ];
        };
    in (mapAttrs mkPublic cfg.publicSites) // (mapAttrs mkPrivate cfg.privateSites);
  };
}
