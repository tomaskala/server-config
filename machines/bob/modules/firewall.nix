{ config, lib, util, ... }:

let
  cfg = config.services.firewall;
  deviceCfg = config.networking.intranet.devices.bob;

  lanInterface = deviceCfg.external.lan.name;
  vpnInterface = deviceCfg.wireguard.isolated.name;
  privateSubnet = deviceCfg.wireguard.isolated.subnet;
in {
  options.services.firewall = { enable = lib.mkEnableOption "firewall"; };

  config = lib.mkIf cfg.enable {
    networking.firewall.enable = false;
    networking.nftables = {
      enable = true;
      checkRuleset = true;

      tables = {
        firewall = {
          family = "inet";
          content = ''
            set tcp_accepted_lan {
              type inet_service
              elements = {
                22,
                53,
                80,
              }
            }

            set tcp_accepted_vpn {
              type inet_service
              elements = {
                ${
                  lib.optionalString
                  config.services.prometheus.exporters.node.enable
                  (builtins.toString
                    config.services.prometheus.exporters.node.port)
                }
              }
            }

            set udp_accepted_lan {
              type inet_service
              elements = {
                53,
              }
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

              # Allow the specified TCP ports from the private subnet.
              iifname ${lanInterface} ip saddr ${
                util.ipSubnet privateSubnet.ipv4
              } tcp dport @tcp_accepted_lan ct state new accept
              iifname ${lanInterface} ip6 saddr ${
                util.ipSubnet privateSubnet.ipv6
              } tcp dport @tcp_accepted_lan ct state new accept

              # Allow the specified UDP ports from the private subnet.
              iifname ${lanInterface} ip saddr ${
                util.ipSubnet privateSubnet.ipv4
              } udp dport @udp_accepted_lan ct state new accept
              iifname ${lanInterface} ip6 saddr ${
                util.ipSubnet privateSubnet.ipv6
              } udp dport @udp_accepted_lan ct state new accept

              # Allow the specified TCP and UDP ports from the VPN.
              iifname ${vpnInterface} tcp dport @tcp_accepted_lan ct state new accept
              iifname ${vpnInterface} udp dport @udp_accepted_lan ct state new accept
              iifname ${vpnInterface} tcp dport @tcp_accepted_vpn ct state new accept
            }

            chain forward {
              type filter hook forward priority 0; policy drop;

              # Allow all established and related traffic.
              ct state established,related accept

              # Allow VPN peers to access the internal subnet.
              iifname ${vpnInterface} oifname ${lanInterface} ct state new accept
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

              # Masquerade VPN traffic to the internal subnet.
              oifname ${lanInterface} iifname ${vpnInterface} masquerade
            }
          '';
        };
      };
    };
  };
}
