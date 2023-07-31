{ config, lib, ... }:

let cfg = config.services.unbound;
in {
  options.services.unbound = {
    localDomains = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          ipv4 = lib.mkOption {
            type = lib.types.str;
            description = "IPv4 address the domain resolves to";
            example = "192.168.0.1";
          };

          ipv6 = lib.mkOption {
            type = lib.types.str;
            description = "IPv6 address the domain resolves to";
            example = "fe80::1";
          };
        };
      });
      description = "Locally-resolvable domains and their addresses";
    };
  };

  config.services.unbound = {
    enableRootTrustAnchor = true;
    resolveLocalQueries = false;

    settings = {
      server = {
        # Basic settings.
        do-ip4 = true;
        do-ip6 = true;
        do-udp = true;
        do-tcp = true;
        edns-buffer-size = 1232;

        # Local zones.
        private-domain = builtins.attrNames cfg.localDomains;
        local-zone = builtins.map (domain: ''"${domain}." redirect'')
          (builtins.attrNames cfg.localDomains);
        local-data = builtins.concatLists (lib.mapAttrsToList (domain:
          { ipv4, ipv6 }: [
            ''"${domain}. A ${ipv4}"''
            ''"${domain}. AAAA ${ipv6}"''
          ]) cfg.localDomains);

        # Logging settings.
        verbosity = 1;

        # Security and privacy settings.
        aggressive-nsec = true;
        qname-minimisation = true;
        qname-minimisation-strict = false;
        deny-any = true;
        harden-below-nxdomain = true;
        harden-dnssec-stripped = true;
        harden-glue = true;
        hide-identity = true;
        hide-version = true;
        identity = "dns";
        private-address = [
          "192.168.0.0/16"
          "169.254.0.0/16"
          "172.16.0.0/12"
          "10.0.0.0/8"
          "fd00::/8"
          "fe80::/10"
        ];
        unwanted-reply-threshold = 10000;
        use-caps-for-id = false;
        val-clean-additional = true;

        # Performance settings.
        num-threads = 1;
        infra-cache-slabs = 1;
        key-cache-slabs = 1;
        msg-cache-slabs = 1;
        rrset-cache-slabs = 1;
        rrset-cache-size = "128m";
        key-cache-size = "64m";
        msg-cache-size = "64m";
        neg-cache-size = "64m";
        minimal-responses = true;
        prefetch = true;
        prefetch-key = true;
        so-reuseport = true;
        outgoing-range = 950;
        so-rcvbuf = "1m";
      };

      forward-zone = [{
        name = ".";
        forward-tls-upstream = true;
        forward-addr = [
          "9.9.9.9@853#dns.quad9.net"
          "149.112.112.112@853#dns.quad9.net"
          "2620:fe::fe@853#dns.quad9.net"
          "2620:fe::9@853#dns.quad9.net"
        ];
      }];
    };
  };
}
