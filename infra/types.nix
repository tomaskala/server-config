{ lib, ... }:

let
  ipv4Address = lib.types.submodule {
    options = {
      type = lib.mkOption {
        type = lib.types.str;
        description = "Type of the IP address";
        default = "ipv4";
      };

      location = lib.mkOption {
        type = lib.types.int;
        description = "Location within the intranet";
        readOnly = true;
      };

      subnet = lib.mkOption {
        type = lib.types.int;
        description = "Subnet within this IP address' location";
        readOnly = true;
      };

      host = lib.mkOption {
        type = lib.types.int;
        description = "Host number within this IP address' subnet";
        readOnly = true;
      };
    };
  };

  ipv6Address = lib.types.submodule {
    options = {
      type = lib.mkOption {
        type = lib.types.str;
        description = "Type of the IP address";
        default = "ipv6";
      };

      location = lib.mkOption {
        type = lib.types.int;
        description = "Location within the intranet";
        readOnly = true;
      };

      subnet = lib.mkOption {
        type = lib.types.int;
        description = "Subnet within this IP address' location";
        readOnly = true;
      };

      host = lib.mkOption {
        type = lib.types.int;
        description = "Host number within this IP address' subnet";
        readOnly = true;
      };
    };
  };

  ipv4Subnet = lib.types.submodule {
    options = {
      type = lib.mkOption {
        type = lib.types.str;
        description = "Type of the IP subnet";
        default = "ipv4";
      };

      location = lib.mkOption {
        type = lib.types.int;
        description = "Location within the intranet";
        readOnly = true;
      };

      subnet = lib.mkOption {
        type = lib.types.int;
        description = "Subnet within this IP subnet's location";
        readOnly = true;
      };

      mask = lib.mkOption {
        type = lib.types.int;
        description = "Subnet mask";
        readOnly = true;
      };
    };
  };

  ipv6Subnet = lib.types.submodule {
    options = {
      type = lib.mkOption {
        type = lib.types.str;
        description = "Type of the IP subnet";
        default = "ipv6";
      };

      location = lib.mkOption {
        type = lib.types.int;
        description = "Location within the intranet";
        readOnly = true;
      };

      subnet = lib.mkOption {
        type = lib.types.int;
        description = "Subnet within this IP subnet's location";
        readOnly = true;
      };

      mask = lib.mkOption {
        type = lib.types.int;
        description = "Subnet mask";
        readOnly = true;
      };
    };
  };

  networkInterface = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Name of this interface";
        readOnly = true;
      };

      ipv4 = lib.mkOption {
        type = lib.types.either lib.types.str ipv4Address;
        description = "IPv4 address of this interface";
        readOnly = true;
      };

      ipv6 = lib.mkOption {
        type = lib.types.either lib.types.str ipv6Address;
        description = "IPv6 address of this interface";
        readOnly = true;
      };
    };
  };

  wireguardInterface = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Name of this interface";
        readOnly = true;
      };

      privateKeyFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        description = "Path to the private key file, if Nix-managed";
        readOnly = true;
      };

      publicKey = lib.mkOption {
        type = lib.types.str;
        description = "Public key of this interface";
        readOnly = true;
      };

      port = lib.mkOption {
        type = lib.types.nullOr lib.types.port;
        description = ''
          The port this interface is listening on, or null if to be
          automatically selected
        '';
        readOnly = true;
      };

      subnet = lib.mkOption {
        type = lib.types.nullOr nonWgSubnet;
        description = "Subnet this interface is a gateway to, if any";
        readOnly = true;
      };

      ipv4 = lib.mkOption {
        type = ipv4Address;
        description = "IPv4 address of this interface";
        readOnly = true;
      };

      ipv6 = lib.mkOption {
        type = ipv6Address;
        description = "IPv6 address of this interface";
        readOnly = true;
      };
    };
  };

  wireguardConnection = lib.types.submodule {
    options = {
      interface = lib.mkOption {
        type = wireguardInterface;
        description = "Interface of the WireGuard peer";
        readOnly = true;
      };

      presharedKeyFile = lib.mkOption {
        type = lib.types.str;
        description = "Path to the preshared key for this connection";
        readOnly = true;
      };
    };
  };

  syncthingConfig = lib.types.submodule {
    options = {
      id = lib.mkOption {
        type = lib.types.str;
        description = "Syncthing device ID";
        readOnly = true;
      };

      introducer = lib.mkOption {
        type = lib.types.bool;
        description = "Whether this device serves as an introducer";
        readOnly = true;
      };

      ipv4 = lib.mkOption {
        type = ipv4Address;
        description = "Syncthing IPv4 address of this device";
        readOnly = true;
      };

      ipv6 = lib.mkOption {
        type = ipv6Address;
        description = "Syncthing IPv6 address of this device";
        readOnly = true;
      };
    };
  };

  device = lib.types.submodule {
    options = {
      syncthing = lib.mkOption {
        type = lib.types.nullOr syncthingConfig;
        description = "Syncthing configuration of this device";
        default = null;
      };

      wireguard = lib.mkOption {
        type = lib.types.attrsOf wireguardInterface;
        description = "WireGuard interfaces of this device";
        readOnly = true;
      };

      external = lib.mkOption {
        type = lib.types.attrsOf networkInterface;
        description = "Non-WireGuard interfaces of this devices";
        readOnly = true;
      };
    };
  };

  service = lib.types.submodule {
    options = {
      url = lib.mkOption {
        type = lib.types.str;
        description = "URL of the service";
        readOnly = true;
      };

      ipv4 = lib.mkOption {
        type = ipv4Address;
        description = "IPv4 address of the service";
        readOnly = true;
      };

      ipv6 = lib.mkOption {
        type = ipv6Address;
        description = "IPv6 address of the service";
        readOnly = true;
      };
    };
  };

  wgSubnet = lib.types.submodule {
    options = {
      ipv4 = lib.mkOption {
        type = ipv4Subnet;
        description = "IPv4 range of this subnet";
        readOnly = true;
      };

      ipv6 = lib.mkOption {
        type = ipv6Subnet;
        description = "IPv6 range of this subnet";
        readOnly = true;
      };

      devices = lib.mkOption {
        type = lib.types.listOf wireguardConnection;
        description = "Devices connected to this subnet";
        readOnly = true;
      };

      services = lib.mkOption {
        type = lib.types.attrsOf service;
        description = "Services running inside this subnet";
        default = { };
      };
    };
  };

  nonWgSubnet = lib.types.submodule {
    options = {
      ipv4 = lib.mkOption {
        type = ipv4Subnet;
        description = "IPv4 range of this subnet";
        readOnly = true;
      };

      ipv6 = lib.mkOption {
        type = ipv6Subnet;
        description = "IPv6 range of this subnet";
        readOnly = true;
      };

      services = lib.mkOption {
        type = lib.types.attrsOf service;
        description = "Services running inside this subnet";
        default = { };
      };
    };
  };
in { inherit ipv4Address ipv6Address device wgSubnet nonWgSubnet; }
