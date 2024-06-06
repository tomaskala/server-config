{ config, pkgs, secrets, ... }:

{
  imports = [
    ./home.nix
    ./modules/audio.nix
    ./modules/firewall.nix
    ./modules/fonts.nix
    ./modules/network.nix
    ./modules/phone.nix
    ./modules/printing.nix
    ./modules/sway.nix
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
      trusted-users = [ "root" "tomas" ];
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

      users = {
        root.hashedPasswordFile = config.age.secrets.users-root-password.path;

        tomas = {
          isNormalUser = true;
          extraGroups = [ "wheel" "wireshark" ];
          hashedPasswordFile = config.age.secrets.users-tomas-password.path;
          shell = pkgs.zsh;
        };
      };
    };

    time.timeZone = "Europe/Prague";

    programs = {
      firefox.enable = true;

      git = {
        enable = true;
        lfs.enable = true;
      };

      neovim = {
        enable = true;
        defaultEditor = true;
        vimAlias = true;
      };

      ssh.startAgent = true;

      wireshark = {
        enable = true;
        package = pkgs.wireshark-qt;
      };

      zsh.enable = true;
    };

    environment.systemPackages = with pkgs; [
      # System utilities
      bc
      fzf
      htop
      man-pages
      man-pages-posix
      ripgrep
      rsync
      tmux
      tree

      # Networking
      curl
      ldns
      openssl
      tcpdump
      whois
      wireguard-tools

      # Internet
      thunderbird

      # Development
      gnumake
      shellcheck

      # Media
      mpv
      yt-dlp
      zathura

      # Communication
      discord
      telegram-desktop

      # Miscellaneous
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
