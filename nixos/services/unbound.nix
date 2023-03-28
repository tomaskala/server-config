{ config, ... }:

let
  # TODO: The definitions should be moved once nginx is configured.
  localDomains = [
    { domain = config.domain;
      ipv4 = config.intranet.server.ipv4;
      ipv6 = config.intranet.server.ipv6;
    }
    { domain = "rss.home.arpa";
      ipv4 = config.intranet.server.ipv4;
      ipv6 = config.intranet.server.ipv6;
    }
  ];
in {
  services.unbound = {
    enableRootTrustAnchor = true;
    settings = {
      server = {
        # Basic settings.
        do-ip4 = true;
        do-ip6 = true;
        do-udp = true;
        do-tcp = true;
        edns-buffer-size = 1232;

        # Access settings.
        interface = [
          config.intranet.server.ipv4
          config.intranet.server.ipv6
        ];
        port = 53;
        access-control = [
          "${config.maskedSubnet config.intranet.ipv4} allow"
          "${config.maskedSubnet config.intranet.ipv6} allow"
        ];

        # Local zones.
        private-domain = catAttrs "domain" localDomains;
        local-zone = map (domain: "${domain}. redirect") (catAttrs "domain" localDomains);
        local-data = concatMap ({ domain, ipv4, ipv6 }: [ "${domain}. A ${ipv4}" "${domain}. AAAA ${ipv6}" ]) localDomains;

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

      forward-zone = [
        { name = ".";
          forward-tls-upstream = true;
          forward-addr = [
            "9.9.9.9@853#dns.quad9.net"
            "149.112.112.112@853#dns.quad9.net"
            "2620:fe::fe@853#dns.quad9.net"
            "2620:fe::9@853#dns.quad9.net"
          ];
        }
      ];

      remote-control = {
        control-enable = true;
        control-port = 8953;
      };
    };
  };
}
