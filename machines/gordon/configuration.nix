{ lib, pkgs, ... }:

{
  services.nix-daemon.enable = true;

  nix.settings = {
    # Disabled because of https://github.com/NixOS/nix/issues/7273.
    auto-optimise-store = lib.mkForce false;
    trusted-users = [ "root" "tomas" ];
  };

  users.users.tomas = {
    home = "/Users/tomas";
    description = "tomas";
  };

  programs = {
    fish.enable = true;
    tmux.enable = true;
    zsh.enable = true;

    direnv = {
      enable = true;
      silent = true;
    };
  };

  environment = {
    shells = [ pkgs.zsh ];

    systemPackages = with pkgs; [
      # System utilities
      coreutils
      fzf
      gawk
      gnugrep
      gnused
      gnutar
      htop
      jq
      ripgrep
      rsync
      tree

      # Development
      git
      gnumake
      go
      gotools
      lua
      python3
      shellcheck
      unstable.neovim

      # Media
      hugo
      yt-dlp

      # Networking
      ldns
      nmap
      openssl
      whois
    ];
  };

  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false;
      cleanup = "zap";
    };

    masApps = {
      Bitwarden = 1352778147;
      Slack = 803453959;
      WireGuard = 1451685025;
    };

    # Curl should be installed using homebrew, as the nixpkgs version has
    # issues with finding ca-certificates.
    # https://github.com/NixOS/nixpkgs/issues/283793
    brews = [ "curl" ];

    casks = [
      "discord"
      "firefox"
      "iina"
      "iterm2"
      "telegram"
      "tunnelblick"
      "visual-studio-code"
      "wireshark"
    ];
  };

  networking = {
    computerName = "gordon";
    hostName = "gordon";
  };

  security.pam.enableSudoTouchIdAuth = true;

  system = {
    # activateSettings -u will reload the settings from the database and apply
    # them to the current session, so we do not need to log out and log in
    # again to make the changes take effect.
    # The script is run every time the system boots or darwin-rebuild runs.
    activationScripts.postUserActivation.text = ''
      /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
    '';

    defaults = {
      smb.NetBIOSName = "gordon";

      dock = {
        autohide = true;
        show-recents = false;
        mru-spaces = false;
      };

      finder = {
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        FXDefaultSearchScope = "SCcf";
        FXEnableExtensionChangeWarning = false;
        QuitMenuItem = true;
        ShowPathbar = true;
        ShowStatusBar = true;
        _FXShowPosixPathInTitle = true;
      };

      trackpad = {
        Clicking = true;
        TrackpadRightClick = true;
        TrackpadThreeFingerDrag = false;
      };

      NSGlobalDomain = {
        # Enable natural scrolling.
        "com.apple.swipescrolldirection" = true;
        # Do not beep when changing volume.
        "com.apple.sound.beep.feedback" = 0;

        # Sensible behavior for pressing and holding keys, useful in vim.
        ApplePressAndHoldEnabled = true;
        InitialKeyRepeat = 15;
        KeyRepeat = 3;

        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticDashSubstitutionEnabled = false;
        NSAutomaticPeriodSubstitutionEnabled = false;
        NSAutomaticQuoteSubstitutionEnabled = false;
        NSAutomaticSpellingCorrectionEnabled = false;

        NSNavPanelExpandedStateForSaveMode = true;
        NSNavPanelExpandedStateForSaveMode2 = true;
        PMPrintingExpandedStateForPrint = true;
        PMPrintingExpandedStateForPrint2 = true;
      };

      CustomUserPreferences = {
        "com.apple.AdLib".allowApplePersonalizedAdvertising = false;
        "com.apple.finder"._FXSortFoldersFirst = true;

        "com.apple.desktopservices" = {
          DSDontWriteNetworkStores = true;
          DSDontWriteUSBStores = true;
        };
      };
    };
  };
}
