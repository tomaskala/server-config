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
    '';
  };
}
