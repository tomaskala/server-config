{ lib, ... }:

let
  # IPv4: 10.<location>.<subnet>.<host>
  ipv4Address =
    {
      location,
      subnet,
      host,
    }:
    "10.${builtins.toString location}.${builtins.toString subnet}.${builtins.toString host}";

  # IPv6: fd25:6f6:<location>:<subnet>::<host>
  ipv6Address =
    {
      location,
      subnet,
      host,
    }:
    "fd25:6f6:${builtins.toString location}:${builtins.toString subnet}::${builtins.toString host}";

  # IPv4: 10.<location>.<subnet>.0/<mask>
  ipv4Subnet =
    {
      location,
      subnet,
      mask,
    }:
    "10.${builtins.toString location}.${builtins.toString subnet}.0/${builtins.toString mask}";

  # IPv6: fd25:6f6:<location>:<subnet>::/<mask>
  ipv6Subnet =
    {
      location,
      subnet,
      mask,
    }:
    "fd25:6f6:${builtins.toString location}:${builtins.toString subnet}::/${builtins.toString mask}";
in
rec {
  types = import ./types.nix { inherit lib; };

  ipAddress =
    addr@{ type, ... }:
    if type == "ipv4" then
      ipv4Address (builtins.removeAttrs addr [ "type" ])
    else if type == "ipv6" then
      ipv6Address (builtins.removeAttrs addr [ "type" ])
    else
      throw "Unrecognized IP address type: ${type}";

  ipAddressMasked = addr: mask: "${ipAddress addr}/${builtins.toString mask}";

  ipSubnet =
    subnet@{ type, ... }:
    if type == "ipv4" then
      ipv4Subnet (builtins.removeAttrs subnet [ "type" ])
    else if type == "ipv6" then
      ipv6Subnet (builtins.removeAttrs subnet [ "type" ])
    else
      throw "Unrecognized IP subnet type: ${type}";
}
