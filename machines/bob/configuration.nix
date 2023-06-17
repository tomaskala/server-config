{ config, pkgs, ... }:

let
  hostName = "bob";
  wanInterface = "eth0";

  intranetCfg = config.networking.intranet;
in {
  imports =
    [ ./secrets-management.nix ../intranet.nix ../../services/openssh.nix ];

  config = {
    system.stateVersion = "23.05";
    # TODO: Autoupgrade?

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

    users.users.tomas = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      passwordFile = config.age.secrets."users-tomas-password-${hostName}".path;
      openssh.authorizedKeys.keys = [
        # TODO
      ];
    };

    time.timeZone = "Europe/Prague";
    services.ntp.enable = false;
    services.timesyncd.enable = true;

    environment.systemPackages = with pkgs; [
      curl
      git
      htop
      ldns
      rsync
      tmux
      tree
      wireguard-tools
    ];

    programs.vim.defaultEditor = true;

    networking.hostName = hostName;
    networking.firewall.enable = false;
    networking.nftables = {
      enable = true;
      ruleset = import ./nftables-ruleset.nix { inherit config wanInterface; };
      checkRuleset = true;
    };

    services.openssh = {
      enable = true;
      ports = [ 22 ];
      listenAddresses = [
        { addr = intranetCfg.gateways."${hostName}".gateway.ipv4; }
        { addr = intranetCfg.gateways."${hostName}".gateway.ipv6; }
        { addr = intranetCfg.gateways."${hostName}".address.ipv4; }
        { addr = intranetCfg.gateways."${hostName}".address.ipv6; }
      ];
    };

    # TODO: navidrome
    # TODO: overlay network
  };
}
