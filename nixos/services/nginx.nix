{
  config.services.nginx = {
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    serverTokens = false;

    # Only allow PFS-enabled ciphers with AES256.
    sslCiphers = "AES256+EECDH:AES256+EDH:!aNULL";

    commonHttpConfig = ''
      # Disable directory listing.
      autoindex off;

      # Add HSTS header with preloading to HTTPS requests.
      # Adding this header to HTTP requests is discouraged.
      map $scheme $hsts_header {
        https "max-age=31536000; includeSubdomains; preload";
      }
    '';
  };
}
