{ config, pkgs, lib, ... }:

let
  cfg = config.services.unbound-blocker;

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
in {
  options.services.unbound-blocker = {
    enable = lib.mkEnableOption "unbound-blocker";
  };

  config = lib.mkIf cfg.enable {
    services.unbound.settings.remote-control.control-enable = true;

    systemd.services.unbound-blocker = {
      description = "DNS blocklist filling script";
      after = [ "unbound.service" ];
      wantedBy = [ "unbound.service" ];
      startAt = "Sun *-*-* 05:00:00";

      serviceConfig = {
        User = config.services.unbound.user;
        Group = config.services.unbound.group;
        Type = "oneshot";
        ExecStart = let
          sourcesFile = pkgs.writeTextFile {
            name = "dns-blocker-sources.txt";
            text = builtins.concatStringsSep "\n" sources;
          };

          whitelistFile = pkgs.writeTextFile {
            name = "dns-blocker-whitelist.txt";
            text = builtins.concatStringsSep "\n" whitelist;
          };
        in ''
          ${pkgs.unbound-blocker}/bin/fetch_blocklist ${sourcesFile} ${
            lib.cli.toGNUCommandLineShell { } {
              whitelist = whitelistFile;

              unbound-control = "${pkgs.unbound}/bin/unbound-control";
            }
          }
        '';
        DevicePolicy = "closed";
        NoNewPrivileges = true;
        PrivateTmp = true;
        PrivateUsers = true;
        ProtectControlGroups = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        # The initial '~' character specifies that this is a deny list.
        SystemCallFilter = [
          "~@clock"
          "@debug"
          "@module"
          "@mount"
          "@obsolete"
          "@reboot"
          "@setuid"
          "@swap"
        ];
        PrivateDevices = true;
        ProtectSystem = "strict";
        ProtectHome = true;
      };
    };
  };
}
