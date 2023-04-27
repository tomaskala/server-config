{ config, writeTextFile, wanInterface }:

# TODO: Use named counters and rule comments (those visible in logs).
let
  serverCfg = config.intranet.server;
in
writeTextFile {
  name = "nftables-ruleset";
  text = ''
    flush ruleset

    table inet firewall {
        # TCP destination ports accepted from WAN and the VPN.
        set tcp_accepted_wan {
            type inet_service
            elements = {
                80,
                443,
            }
        }

        # TCP destination ports accepted from the VPN only.
        set tcp_accepted_vpn {
            type inet_service
            elements = {
                22,
                53,
            }
        }

        # UDP destination ports accepted from WAN and the VPN.
        set udp_accepted_wan {
            type inet_service
            elements = {
                ${serverCfg.port},
            }
        }

        # UDP destination ports accepted from the VPN only.
        set udp_accepted_vpn {
            type inet_service
            elements = {
                53,
            }
        }

        # VPN IPv4 subnets with full access.
        # Managed dynamically by the overlay-network service.
        set vpn_internal_ipv4 {
            type ipv4_addr
            flags interval
        }

        # VPN IPv6 subnets with full access.
        # Managed dynamically by the overlay-network service.
        set vpn_internal_ipv6 {
            type ipv6_addr
            flags interval
        }

        # VPN IPv4 subnets with restricted access.
        # Managed dynamically by the overlay-network service.
        set vpn_isolated_ipv4 {
            type ipv4_addr
            flags interval
        }

        # VPN IPv6 subnets with restricted access.
        # Managed dynamically by the overlay-network service.
        set vpn_isolated_ipv6 {
            type ipv6_addr
            flags interval
        }

        # VPN IPv4 subnets accessible by peers.
        # Managed dynamically by the overlay-network service.
        set vpn_accessible_ipv4 {
            type ipv4_addr
            flags interval
        }

        # VPN IPv6 subnets accessible by peers.
        # Managed dynamically by the overlay-network service.
        set vpn_accessible_ipv6 {
            type ipv6_addr
            flags interval
        }

        chain input {
            type filter hook input priority 0; policy drop;

            # Limit ping requests.
            ip protocol icmp icmp type echo-request limit rate over 1/second burst 5 packets drop
            ip6 nexthdr icmpv6 icmpv6 type echo-request limit rate over 1/second burst 5 packets drop

            # Allow all established and related traffic.
            ct state established,related accept

            # Allow loopback.
            iif lo accept

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

            # Allow the specified TCP and UDP ports from the outside.
            iifname ${wanInterface} tcp dport @tcp_accepted_wan ct state new accept
            iifname ${wanInterface} udp dport @udp_accepted_wan ct state new accept

            # Allow the specified TCP and UDP ports from the VPN.
            iifname ${serverCfg.interface} tcp dport @tcp_accepted_vpn ct state new accept
            iifname ${serverCfg.interface} udp dport @udp_accepted_vpn ct state new accept
            iifname ${serverCfg.interface} tcp dport @tcp_accepted_wan ct state new accept
            iifname ${serverCfg.interface} udp dport @udp_accepted_wan ct state new accept
        }

        chain forward {
            type filter hook forward priority 0; policy drop;

            # Allow all established and related traffic.
            ct state established,related accept

            # Allow internal VPN traffic to access the internet via wan.
            iifname ${serverCfg.interface} ip saddr @vpn_internal_ipv4 oifname ${wanInterface} ct state new accept
            iifname ${serverCfg.interface} ip6 saddr @vpn_internal_ipv6 oifname ${wanInterface} ct state new accept

            # Allow internal VPN peers to communicate with each other.
            iifname ${serverCfg.interface} ip saddr @vpn_internal_ipv4 oifname ${serverCfg.interface} ip daddr @vpn_internal_ipv4 ct state new accept
            iifname ${serverCfg.interface} ip6 saddr @vpn_internal_ipv6 oifname ${serverCfg.interface} ip6 daddr @vpn_internal_ipv6 ct state new accept

            # Allow isolated VPN peers to communicate with each other.
            iifname ${serverCfg.interface} ip saddr @vpn_isolated_ipv4 oifname ${serverCfg.interface} ip daddr @vpn_isolated_ipv4 ct state new accept
            iifname ${serverCfg.interface} ip6 saddr @vpn_isolated_ipv6 oifname ${serverCfg.interface} ip6 daddr @vpn_isolated_ipv6 ct state new accept

            # Allow all VPN traffic to the accessible subnets.
            iifname ${serverCfg.interface} ip daddr @vpn_accessible_ipv4 oifname ${serverCfg.interface} ct state new accept
            iifname ${serverCfg.interface} ip6 daddr @vpn_accessible_ipv6 oifname ${serverCfg.interface} ct state new accept
        }

        chain output {
            type filter hook output priority 0; policy drop;

            # Explicitly allow outgoing traffic; ICMPv6 must be set manually.
            ip6 nexthdr ipv6-icmp accept
            ct state new,established,related accept
        }
    }

    table inet router {
        chain postrouting {
            type nat hook postrouting priority 100;

            # Masquerade VPN traffic to WAN.
            oifname ${wanInterface} ip saddr ${config.maskedSubnet config.intranet.ipv4} masquerade
            oifname ${wanInterface} ip6 saddr ${config.maskedSubnet config.intranet.ipv6} masquerade

            # Masquerade VPN traffic to VPN.
            oifname ${serverCfg.interface} ip saddr ${config.maskedSubnet config.intranet.ipv4} masquerade
            oifname ${serverCfg.interface} ip6 saddr ${config.maskedSubnet config.intranet.ipv6} masquerade
        }
    }

    table netdev filter {
        # IPv4 bogons.
        set ipv4_blocklist {
            type ipv4_addr
            flags interval
            elements = {
                0.0.0.0/8,
                10.0.0.0/8,
                100.64.0.0/10,
                127.0.0.0/8,
                169.254.0.0/16,
                172.16.0.0/12,
                192.0.0.0/24,
                192.0.2.0/24,
                192.168.0.0/16,
                198.18.0.0/15,
                198.51.100.0/24,
                203.0.113.0/24,
                224.0.0.0/4,
                240.0.0.0/4,
            }
        }

        chain ingress {
            # The priority ensures that the chain will be evaluated before any
            # other registered on the ingress hook.
            type filter hook ingress device ${wanInterface} priority -500;

            # Drop IP fragments.
            ip frag-off & 0x1fff != 0 counter drop

            # Drop bad addresses.
            ip saddr @ipv4_blocklist counter drop

            # Drop bad TCP flags.
            tcp flags & (fin|syn|rst|ack) == 0x0 counter drop
            tcp flags & (fin|syn) == fin|syn counter drop
            tcp flags & (fin|rst) == fin|rst counter drop
            tcp flags & (fin|ack) == fin counter drop
            tcp flags & (fin|urg) == fin|urg counter drop
            tcp flags & (syn|rst) == syn|rst counter drop
            tcp flags & (rst|urg) == rst|urg counter drop

            # Drop uncommon MSS values.
            tcp flags syn tcp option maxseg size 1-535 counter drop
        }
    }

    table inet mangle {
        chain prerouting {
            type filter hook prerouting priority -150;

            # Drop invalid packets.
            ct state invalid counter drop

            # Drop new TCP packets that are not SYN.
            tcp flags & (fin|syn|rst|ack) != syn ct state new counter drop
        }
    }
  '';
}
