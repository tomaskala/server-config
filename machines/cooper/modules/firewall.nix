{
  networking.firewall.enable = false;
  networking.nftables = {
    enable = true;
    checkRuleset = true;

    tables = {
      firewall = {
        family = "inet";
        content = ''
          chain input {
            type filter hook input priority 0; policy drop;

            # Limit ping requests.
            ip protocol icmp icmp type echo-request limit rate over 1/second burst 5 packets drop
            ip6 nexthdr icmpv6 icmpv6 type echo-request limit rate over 1/second burst 5 packets drop

            # Allow all established and related traffic.
            ct state established,related accept

            # Allow loopback.
            iifname lo accept

            # Allow specific ICMP types.
            ip protocol icmp icmp type {
              destination-unreachable,
              echo-reply,
              echo-request,
              source-quench,
              time-exceeded,
            } accept

            # Allow specific ICMPv6 types.
            ip6 nexthdr icmpv6 icmpv6 type {
              destination-unreachable,
              echo-reply,
              echo-request,
              nd-neighbor-advert,
              nd-neighbor-solicit,
              nd-router-advert,
              packet-too-big,
              parameter-problem,
              time-exceeded,
            } accept
          }

          chain forward {
            type filter hook forward priority 0; policy drop;
          }

          chain output {
            type filter hook output priority 0; policy drop;

            # Explicitly allow outgoing traffic; ICMPv6 must be set manually.
            ip6 nexthdr ipv6-icmp accept
            ct state new,established,related accept
          }
        '';
      };
    };
  };
}
