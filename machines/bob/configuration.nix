{ config, pkgs, ... }:

let
  hostName = "bob";
  wanInterface = "eth0";
in {
  imports = [ ./secrets-management.nix ../../services/openssh.nix ];

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
        # TODO
      ];
    };

    # TODO: navidrome
    # TODO: overlay network
  };
}
