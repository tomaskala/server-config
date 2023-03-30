{ config, ... }:

{
  security.acme = {
    acceptTerms = true;
    certs.${config.domain} = {
      webroot = "/var/lib/acme/.challenges";
      email = config.email.acme;
      # The webserver must be able to read the generated certificates.
      group = config.users.users.nginx.group;
    };
  };

  # /var/lib/acme/.challenges must be writable by the ACME user
  # and readable by the Nginx user.
  users.users.nginx.extraGroups = [ "acme" ];

  services.nginx = {
    virtualHosts."certs.${config.domain}" = {
      serverAliases = [ "*.${domain}" ];

      locations."/.well-known/acme-challenge" = {
        root = "/var/lib/acme/.challenges";
      };

      locations."/" = {
        return = "301 https://$host$request_uri";
      };
    };
  };
}
