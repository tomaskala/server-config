{ config, pkgs, secrets, ... }:

{
  # TODO: https://codeberg.org/davidak/nixos-config
  # TODO: home-manager

  imports = [
    ./home.nix
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
    ../intranet.nix
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

    age = {
      identityPaths = [ "/home/tomas/.ssh/id_ed25519_agenix" ];

      secrets = {
        users-tomas-password.file = "${secrets}/secrets/users/cooper/tomas.age";
        users-root-password.file = "${secrets}/secrets/users/cooper/root.age";

        wg-cooper-internal-pk = {
          file = "${secrets}/secrets/wg-pk/cooper/internal.age";
          mode = "0640";
          owner = "root";
          group = "systemd-network";
        };

        wg-cooper2whitelodge = {
          file = "${secrets}/secrets/wg-psk/cooper2whitelodge.age";
          mode = "0640";
          owner = "root";
          group = "systemd-network";
        };
      };
    };

    users = {
      mutableUsers = false;

      root.hashedPasswordFile = config.age.secrets.users-root-password.path;

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
