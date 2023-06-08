{ config, pkgs, ... }:

# TODO: Pull secrets from a private repository.

let
  publicDomain = "tomaskala.com";
  publicDomainWebroot = "/var/www/${publicDomain}";
  acmeEmail = "public+acme@${publicDomain}";

  rssDomain = "rss.home.arpa";
  rssListenPort = 7070;

  wanInterface = "venet0";

  maskSubnet = { subnet, mask }: "${subnet}/${builtins.toString mask}";
  intranetCfg = config.networking.intranet;
in {
  imports = [
    ./overlay-network.nix
    ./secrets-management.nix
    ../intranet.nix
    ../../services/openssh.nix
    ../../services/unbound-blocker.nix
    ../../services/unbound.nix
    ../../services/yarr.nix
  ];

  config = {
    nix = {
      gc = {
        automatic = true;
        dates = "weekly";
      };

      settings = {
        auto-optimise-store = true;
        experimental-features = [ "nix-command" "flakes" ];
      };
    };

    # TODO: https://nixos.wiki/wiki/Overlays
    # TODO: https://summer.nixos.org/blog/callpackage-a-tool-for-the-lazy/
    nixpkgs.overlays = [
      (self: super: {
        unbound-blocker = super.callPackage ../../pkgs/unbound-blocker { };
      })
    ];

    users.users.tomas = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      passwordFile = config.age.secrets.users-tomas-password.path;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGRpAi2U+EW2dhKv/tu2DVJPNZnrqgQway2CSAs38tFl home2whitelodge"
      ];
    };

    users.groups.git = { };
    users.users.git = {
      isSystemUser = true;
      createHome = true;
      home = "/home/git";
      shell = "${pkgs.git}/bin/git-shell";
      group = "git";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIApzsZJs9oocJnP2JnIsSZFmmyWdUm/2IgRHcJgCqFc1 phone2whitelodge-git"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP3iFrxprV/hToSeHEIo2abt/IcK/M86iqF4mV6S81Rf home2whitelodge-git"
      ];
    };

    time.timeZone = "Europe/Prague";
    services.ntp.enable = false;
    services.timesyncd.enable = true;

    programs.vim.defaultEditor = true;
    environment.systemPackages = with pkgs; [
      curl
      git
      ldns
      rsync
      tmux
      wireguard-tools
    ];

    networking.hostName = "whitelodge";
    networking.firewall.enable = false;
    networking.nftables = {
      enable = true;
      checkRuleset = true;
      ruleset = import ./nftables-ruleset.nix { inherit config wanInterface; };
    };

    systemd.network = {
      enable = true;

      netdevs."90-${intranetCfg.server.interface}" = {
        netdevConfig = {
          Name = intranetCfg.server.interface;
          Kind = "wireguard";
        };

        wireguardConfig = {
          PrivateKeyFile = config.age.secrets.wg-server-pk.path;
          ListenPort = intranetCfg.server.port;
        };

        wireguardPeers = [
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
              PublicKey = "b1vNeOy10kbXfldKbaAd5xa2cndgzOE8kQ63HoWXIko=";
              PresharedKeyFile = config.age.secrets.wg-tomas-home-psk.path;
              AllowedIPs = [ "10.100.100.3/32" "fd25:6f6:a9f:1100::3/128" ];
            };
          }
        ];
      };

      networks."90-${intranetCfg.server.interface}" = {
        matchConfig = { Name = intranetCfg.server.interface; };

        address = [
          "${intranetCfg.server.ipv4}/${
            builtins.toString intranetCfg.ipv4.mask
          }"
          "${intranetCfg.server.ipv6}/${
            builtins.toString intranetCfg.ipv6.mask
          }"
        ];
      };
    };

    networking.overlay-network = { enable = true; };

    services.openssh = {
      enable = true;

      listenAddresses = [
        {
          addr = intranetCfg.server.ipv4;
          port = 22;
        }
        {
          addr = intranetCfg.server.ipv6;
          port = 22;
        }
      ];
    };

    services.yarr = {
      enable = true;
      listenPort = rssListenPort;
    };

    services.caddy = {
      enable = true;
      email = acmeEmail;

      virtualHosts.${publicDomain} = {
        extraConfig = ''
          root * ${publicDomainWebroot}
          encode gzip
          file_server
        '';
      };

      # Explicitly specify HTTP to disable automatic TLS certificate creation,
      # since this is an internal domain only accessible from the VPN anyway.
      virtualHosts."http://${rssDomain}" = {
        listenAddresses = [ intranetCfg.server.ipv4 intranetCfg.server.ipv6 ];

        extraConfig = ''
          reverse_proxy :${builtins.toString rssListenPort}

          @blocked not remote_ip ${maskSubnet intranetCfg.ipv4} ${
            maskSubnet intranetCfg.ipv6
          }
          respond @blocked "Forbidden" 403
        '';
      };
    };

    services.unbound = {
      enable = true;

      localDomains = [
        {
          domain = publicDomain;
          inherit (intranetCfg.server) ipv4 ipv6;
        }
        {
          domain = rssDomain;
          inherit (intranetCfg.server) ipv4 ipv6;
        }
      ];
    };

    services.unbound-blocker = {
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
  };
}
