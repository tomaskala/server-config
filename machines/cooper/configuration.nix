{ config, pkgs, secrets, ... }:

{
  imports = [
    ./modules/audio.nix
    ./modules/desktop.nix
    ./modules/firewall.nix
    ./modules/fonts.nix
    ./modules/locale.nix
    ./modules/network.nix
    ./modules/phone.nix
    ./modules/printing.nix
    ./modules/virtualisation.nix
    ./modules/wireguard.nix
    ../../intranet
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

      initrd.systemd.enable = true;

      loader = {
        grub.enable = false;

        systemd-boot = {
          enable = true;
          editor = false;
        };
      };
    };

    systemd.services.nix-daemon.environment.TMPDIR = "/var/tmp";

    nix.settings.trusted-users = [ "root" "tomas" ];

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

      users = {
        root.hashedPasswordFile = config.age.secrets.users-root-password.path;

        tomas = {
          isNormalUser = true;
          extraGroups = [ "audio" "networkmanager" "users" "video" "wheel" "wireshark" ];
          hashedPasswordFile = config.age.secrets.users-tomas-password.path;
          shell = pkgs.zsh;
        };
      };
    };

    programs = {
      firefox.enable = true;
      ssh.startAgent = true;

      wireshark = {
        enable = true;
        package = pkgs.wireshark-qt;
      };
    };

    environment.systemPackages = with pkgs; [
      # System utilities
      man-pages
      man-pages-posix
      rsync
      tree

      # Networking
      curl
      ldns
      nmap
      openssl
      tcpdump
      whois
      wireguard-tools

      # Internet
      thunderbird

      # Development
      gnumake
      go
      gotools
      lua
      python3
      shellcheck

      # Media
      hugo
      libreoffice-still
      zathura

      # Communication
      discord
      telegram-desktop

      # Miscellaneous
      yubikey-manager-qt
    ];

    networking.hostName = "cooper";

    security = {
      polkit.enable = true;

      sudo = {
        enable = true;
        execWheelOnly = true;
      };
    };

    services = {
      ntp.enable = false;
      timesyncd.enable = true;
      # TODO: Also enable boot.initrd.luks.devices.<name>.allowDiscards.
      fstrim.enable = true;
      fwupd.enable = true;
      tlp.enable = true;
    };
  };
}
