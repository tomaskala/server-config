{ config, pkgs, ... }:

# TODO: Make each service's configuration stand-alone? Meaning that the
# RSS configuration file will configure the RSS reader as well as setup
# nginx reverse proxy.

# TODO: Pull secrets from a private repository.

{
  imports = [
    ./constants.nix
    ./acme.nix
    ../intranet.nix
    ../services/blocklist-fetcher.nix
    ../services/nginx.nix
    ../services/openssh.nix
    ../services/unbound.nix
    ../services/yarr.nix
  ];

  config = {
    # TODO: https://nixos.wiki/wiki/Overlays
    # TODO: https://summer.nixos.org/blog/callpackage-a-tool-for-the-lazy/
    nixpkgs.overlays = [
      (self: super: {
        unbound-blocker = super.callPackage ../../pkgs/unbound-blocker { };
      })
    ];

    users.users.tomas = {
      isNormalUser = true;
      home = "/home/tomas";
      extraGroups = [ "wheel" ];
      passwordFile = config.age.secrets.users-tomas-password.path;
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

    age.secrets =
      let
        makeSecretPath = secret: "/root/secrets/${secret}.age";

        makeSecret = acc: secret:
          acc // { "${secret}" = { file = makeSecretPath secret; }; };

        makeSystemdNetworkReadableSecret = acc: secret:
          acc // {
            "${secret}" =
              {
                file = makeSecretPath secret;
                mode = "0640";
                owner = "root";
                group = "systemd-network";
              };
          };

        secrets = foldl' makeSecret { } [
          users-tomas-password
        ];

        systemdNetworkReadableSecrets = foldl' makeSystemdNetworkReadableSecret { } [
          wg-server-pk
          wg-tomas-laptop-psk
          wg-tomas-phone-psk
          wg-martin-windows-psk
          wg-tomas-home-psk
        ];
      in
      secrets // systemdNetworkReadableSecrets;

    systemd.network = {
      netdevs."90-${config.intranet.server.interface}" = {
        netdevConfig = {
          Name = config.intranet.server.interface;
          Kind = "wireguard";
        };

        wireguardConfig = {
          PrivateKeyFile = config.age.secrets.wg-server-pk.path;
          ListenPort = config.intranet.server.port;
        };

        wireguardPeers = [
          {
            wireguardPeerConfig = {
              # tomas-laptop
              PublicKey = "5t3YVZ7+nimeIknRvgn9el1+ZaURG/54MX7vFzPCRFU=";
              PresharedKeyFile = config.age.secrets.wg-tomas-laptop-psk.path;
              AllowedIPs = [ "10.100.100.1/32" "fd25:6f6:a9f:1100::1/128" ];
            };
          }
          {
            wireguardPeerConfig = {
              # tomas-phone
              PublicKey = "DTJ3VeQGDehQBkYiteIpxtatvgqy2Ux/KjQEmXaEoEQ=";
              PresharedKeyFile = config.age.secrets.wg-tomas-phone-psk.path;
              AllowedIPs = [ "10.100.100.2/32" "fd25:6f6:a9f:1100::2/128" ];
            };
          }
          {
            wireguardPeerConfig = {
              # martin-windows
              PublicKey = "JoxRQuYsNZqg/e/DHIVnAsDsA86PjyDlIWPIViMrPUQ=";
              PresharedKeyFile = config.age.secrets.wg-martin-windows-psk.path;
              AllowedIPs = [ "10.100.104.1/32" "fd25:6f6:a9f:1200::1/128" ];
            };
          }
          {
            wireguardPeerConfig = {
              # tomas-home
              PublicKey = "0UGizNBFMqQ858L+FqLwUKMohjKssttH7sMPuIoiuFE=";
              PresharedKeyFile = config.age.secrets.wg-tomas-home-psk.path;
              AllowedIPs = [ "10.100.100.3/32" "fd25:6f6:a9f:1100::3/128" ];
            };
          }
        ];
      };

      networks."90-${config.intranet.server.interface}" = {
        matchConfig = {
          Name = config.intranet.server.interface;
        };

        address = [
          "${config.intranet.server.ipv4}/${builtins.toString config.intranet.ipv4.mask}"
          "${config.intranet.server.ipv6}/${builtins.toString config.intranet.ipv6.mask}"
        ];
      };
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
        {
          domain = config.domains.public;
          ipv4 = config.intranet.server.ipv4;
          ipv6 = config.intranet.server.ipv6;
        }
        {
          domain = config.domains.rss;
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
            valid_referers none blocked ${config.domains.public};
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
    };

    services.blocklist-fetcher = {
      enable = true;
      sources = [
        "https://adaway.org/hosts.txt"
        "https://bitbucket.org/ethanr/dns-blacklists/raw/8575c9f96e5b4a1308f2f12394abd86d0927a4a0/bad_lists/Mandiant_APT1_Report_Appendix_D.txt"
        "https://gitlab.com/quidsup/notrack-blocklists/raw/master/notrack-malware.txt"
        "https://hostfiles.frogeye.fr/firstparty-trackers-hosts.txt"
        "https://osint.digitalside.it/Threat-Intel/lists/latestdomains.txt"
        "https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=0&mimetype=plaintext"
        "https://phishing.army/download/phishing_army_blocklist_extended.txt"
        "https://raw.githubusercontent.com/anudeepND/blacklist/master/adservers.txt"
        "https://raw.githubusercontent.com/AssoEchap/stalkerware-indicators/master/generated/hosts"
        "https://raw.githubusercontent.com/bigdargon/hostsVN/master/hosts"
        "https://raw.githubusercontent.com/crazy-max/WindowsSpyBlocker/master/data/hosts/spy.txt"
        "https://raw.githubusercontent.com/DandelionSprout/adfilt/master/Alternate%20versions%20Anti-Malware%20List/AntiMalwareHosts.txt"
        "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.2o7Net/hosts"
        "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Risk/hosts"
        "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Spam/hosts"
        "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/UncheckyAds/hosts"
        "https://raw.githubusercontent.com/hoshsadiq/adblock-nocoin-list/master/hosts.txt"
        "https://raw.githubusercontent.com/PolishFiltersTeam/KADhosts/master/KADhosts.txt"
        "https://raw.githubusercontent.com/Spam404/lists/master/main-blacklist.txt"
        "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling/hosts"
        "https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt"
        "https://s3.amazonaws.com/lists.disconnect.me/simple_malvertising.txt"
        "https://someonewhocares.org/hosts/hosts"
        "https://urlhaus.abuse.ch/downloads/hostfile/"
        "https://v.firebog.net/hosts/AdguardDNS.txt"
        "https://v.firebog.net/hosts/Admiral.txt"
        "https://v.firebog.net/hosts/Easylist.txt"
        "https://v.firebog.net/hosts/Easyprivacy.txt"
        "https://v.firebog.net/hosts/Prigent-Ads.txt"
        "https://v.firebog.net/hosts/Prigent-Crypto.txt"
        "https://v.firebog.net/hosts/RPiList-Malware.txt"
        "https://v.firebog.net/hosts/RPiList-Phishing.txt"
        "https://v.firebog.net/hosts/static/w3kbl.txt"
        "https://winhelp2002.mvps.org/hosts.txt"
        "https://zerodot1.gitlab.io/CoinBlockerLists/hosts_browser"
      ];
      whitelist = [
        "clients4.google.com"
        "clients2.google.com"
        "s.youtube.com"
        "video-stats.l.google.com"
        "android.clients.google.com"
        "gstaticadssl.l.google.com"
        "dl.google.com"
        "www.msftncsi.com"
        "www.msftconnecttest.com"
        "outlook.office365.com"
        "products.office.com"
        "c.s-microsoft.com"
        "i.s-microsoft.com"
        "login.live.com"
        "login.microsoftonline.com"
        "g.live.com"
        "dl.delivery.mp.microsoft.com"
        "geo-prod.do.dsp.mp.microsoft.com"
        "displaycatalog.mp.microsoft.com"
        "sls.update.microsoft.com.akadns.net"
        "fe3.delivery.dsp.mp.microsoft.com.nsatc.net"
        "tlu.dl.delivery.mp.microsoft.com"
        "msedge.api.cdp.microsoft.com"
        "officeclient.microsoft.com"
        "connectivitycheck.android.com"
        "android.clients.google.com"
        "clients3.google.com"
        "connectivitycheck.gstatic.com"
        "msftncsi.com"
        "www.msftncsi.com"
        "ipv6.msftncsi.com"
        "tracking-protection.cdn.mozilla.net"
        "styles.redditmedia.com"
        "www.redditstatic.com"
        "reddit.map.fastly.net"
        "www.redditmedia.com"
        "reddit-uploaded-media.s3-accelerate.amazonaws.com"
        "ud-chat.signal.org"
        "chat.signal.org"
        "storage.signal.org"
        "signal.org"
        "www.signal.org"
        "updates2.signal.org"
        "textsecure-service-whispersystems.org"
        "giphy-proxy-production.whispersystems.org"
        "cdn.signal.org"
        "whispersystems-textsecure-attachments.s3-accelerate.amazonaws.com"
        "d83eunklitikj.cloudfront.net"
        "souqcdn.com"
        "cms.souqcdn.com"
        "api.directory.signal.org"
        "contentproxy.signal.org"
        "turn1.whispersystems.org"
      ];
    };

    # TODO
    # * overlay network
  };
}
