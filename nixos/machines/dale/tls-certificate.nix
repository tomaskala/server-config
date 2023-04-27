{ config, lib, ... }:

let
  cfg = config.security.tls-certificate;
in
{
  options.security.tls-certificate = {
    enable = lib.mkEnableOption "TLS certificate";

    email = lib.mkOption {
      type = lib.types.str;
      description = "Email address for the CA account creation";
      example = "acme@domain.com";
    };

    domain = lib.mkOption {
      type = lib.types.str;
      description = "Domain which the certificate should be generated for";
      example = "domain.com";
    };

    webroot = lib.mkOption {
      type = lib.types.path;
      description = "Where the domain's webroot is located";
      example = "/var/www/domain.com";
    };
  };

  config.security.tls-certificate = lib.mkIf cfg.enable {
    security.acme = {
      acceptTerms = true;
      certs.${cfg.domain} = {
        webroot = cfg.webroot;
        email = cfg.email;
        # The webserver must be able to read the generated certificates.
        group = config.users.users.nginx.group;
      };
    };

    # /var/lib/acme/.challenges must be writable by the ACME user
    # and readable by the Nginx user.
    users.users.nginx.extraGroups = [ "acme" ];

    services.nginx = {
      virtualHosts."certs.${cfg.domain}" = {
        serverAliases = [ "*.${domain}" ];

        locations."/.well-known/acme-challenge" = {
          root = "/var/lib/acme/.challenges";
        };

        locations."/" = {
          return = "301 https://$host$request_uri";
        };
      };
    };
  };
}
