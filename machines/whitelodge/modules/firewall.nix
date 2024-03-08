{ config, lib, pkgs, ... }:

let
  cfg = config.services.firewall;
  intranetCfg = config.networking.intranet;

  wanInterface = intranetCfg.external.whitelodge.name;
  vpnInterface = {
    internal = intranetCfg.subnets.vpn-internal.gateway.interface.name;
    isolated = intranetCfg.subnets.vpn-isolated.gateway.interface.name;
  };
in {
  options.services.firewall = { enable = lib.mkEnableOption "firewall"; };

  config = lib.mkIf cfg.enable {
    networking.firewall.enable = false;
    networking.nftables = {
      enable = true;

      # Ruleset checking reports errors with chains defined on top of the
      # ingress hook. This hook must be interface-specific, and the ruleset
      # check always fails as it runs in a sandbox. A solution is to rename
      # all occurrences of the WAN interface to the loopback interface, which
      # is available even inside the sandbox.
      # Source: https://github.com/NixOS/nixpkgs/pull/223283/files.
      checkRuleset = true;
      preCheckRuleset = ''
        ${pkgs.gnused}/bin/sed -i 's/${wanInterface}/lo/g' ruleset.conf
      '';

      tables = {
        firewall = {
          family = "inet";
          content = ''
            # TCP destination ports accepted from WAN and the VPN.
            set tcp_accepted_wan {
              type inet_service
              elements = {
                80,
                443,
              }
            }

            # TCP destination ports accepted from the internal VPN only.
            set tcp_accepted_vpn_internal {
              type inet_service
              elements = {
                22,
                53,
              }
            }

            # TCP destination ports accepted from the isolated VPN only.
            set tcp_accepted_vpn_isolated {
              type inet_service
              elements = {
                53,
              }
            }

            # UDP destination ports accepted from WAN and the VPN.
            set udp_accepted_wan {
              type inet_service
              elements = {
                ${
                  builtins.toString
                  intranetCfg.subnets.vpn-internal.gateway.interface.port
                },
                ${
                  builtins.toString
                  intranetCfg.subnets.vpn-isolated.gateway.interface.port
                },
              }
            }

            # UDP destination ports accepted from the internal VPN only.
            set udp_accepted_vpn_internal {
              type inet_service
              elements = {
                53,
              }
            }

            # UDP destination ports accepted from the isolated VPN only.
            set udp_accepted_vpn_isolated {
              type inet_service
              elements = {
                53,
              }
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

              # Allow the specified TCP and UDP ports from the outside.
              iifname ${wanInterface} tcp dport @tcp_accepted_wan ct state new accept
              iifname ${wanInterface} udp dport @udp_accepted_wan ct state new accept

              # Allow the specified TCP and UDP ports from the VPN.
              iifname ${vpnInterface.internal} tcp dport @tcp_accepted_vpn_internal ct state new accept
              iifname ${vpnInterface.internal} udp dport @udp_accepted_vpn_internal ct state new accept
              iifname ${vpnInterface.isolated} tcp dport @tcp_accepted_vpn_isolated ct state new accept
              iifname ${vpnInterface.isolated} udp dport @udp_accepted_vpn_isolated ct state new accept
              ${
                builtins.concatStringsSep "\n" (lib.mapAttrsToList
                  (_: interface: ''
                    iifname ${interface} tcp dport @tcp_accepted_wan ct state new accept
                    iifname ${interface} udp dport @udp_accepted_wan ct state new accept
                  '') vpnInterface)
              }
            }

            chain forward {
              type filter hook forward priority 0; policy drop;

              # Allow all established and related traffic.
              ct state established,related accept

              # Allow internal VPN traffic to access the internet via WAN.
              iifname ${vpnInterface.internal} oifname ${wanInterface} ct state new accept

              # Allow internal VPN peers to communicate with each other.
              iifname ${vpnInterface.internal} oifname ${vpnInterface.internal} ct state new accept

              # Allow isolated VPN peers to communicate with each other.
              iifname ${vpnInterface.isolated} oifname ${vpnInterface.isolated} ct state new accept

              # Allow internal and isolated VPN traffic to the accessible subnets.
              iifname ${vpnInterface.internal} ip daddr @vpn_accessible_ipv4 ct state new accept
              iifname ${vpnInterface.internal} ip6 daddr @vpn_accessible_ipv6 ct state new accept
              iifname ${vpnInterface.isolated} ip daddr @vpn_accessible_ipv4 ct state new accept
              iifname ${vpnInterface.isolated} ip6 daddr @vpn_accessible_ipv6 ct state new accept
            }

            chain output {
              type filter hook output priority 0; policy drop;

              # Explicitly allow outgoing traffic; ICMPv6 must be set manually.
              ip6 nexthdr ipv6-icmp accept
              ct state new,established,related accept
            }
          '';
        };

        router = {
          family = "inet";
          content = ''
            chain postrouting {
              type nat hook postrouting priority 100;

              # Masquerade VPN traffic to WAN.
              oifname ${wanInterface} iifname ${vpnInterface.internal} masquerade
            }
          '';
        };

        filter = {
          family = "netdev";
          content = ''
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
          '';
        };

        mangle = {
          family = "inet";
          content = ''
            chain prerouting {
              type filter hook prerouting priority -150;

              # Drop invalid packets.
              ct state invalid counter drop

              # Drop new TCP packets that are not SYN.
              tcp flags & (fin|syn|rst|ack) != syn ct state new counter drop
            }
          '';
        };
      };
    };
  };
}
