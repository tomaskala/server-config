{ config, pkgs, ... }:

{
  # TODO: https://codeberg.org/davidak/nixos-config
  # TODO: home-manager

  imports = [
    ../intranet.nix
    ./modules/audio.nix
    ./modules/filesystems.nix
    ./modules/firewall.nix
    ./modules/fonts.nix
    ./modules/network.nix
    ./modules/phone.nix
    ./modules/printing.nix
    ./modules/virtualisation.nix
    ./modules/vpn.nix
    ./modules/xserver.nix
    ./secrets-management.nix
  ];

  config = {
    hardware = {
      cpu.amd.updateMicrocode = true;
      enableRedistributableFirmware = true;
    };

    boot = {
      plymouth.enable = true;

      tmp = {
        cleanOnBoot = true;
        useTmpfs = true;
      };

      loader = {
        grub.enable = false;

        systemd-boot = {
          enable = true;
          editor = false;
        };
      };
    };

    nix.settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-commands" "flakes" ];
    };

    users = {
      mutableUsers = false;

      users.tomas = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        hashedPasswordFile = config.age.secrets.users-tomas-password.path;
      };
    };

    time.timeZone = "Europe/Prague";

    # Only system utilities should be installed globally.
    environment.systemPackages = with pkgs; [
      bc
      curl
      git
      htop
      ldns
      rsync
      tmux
      tree
      wireguard-tools
      yubikey-manager-qt
    ];

    networking.hostName = "cooper";

    security.sudo = {
      enable = true;
      execWheelOnly = true;
    };

    services = {
      ntp.enable = false;
      timesyncd.enable = true;
      fstrim.enable = true;
      fwupd.enable = true;
      tlp.enable = true;
    };
  };
}
