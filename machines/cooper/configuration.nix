{ pkgs, ... }:

{
  services.nix-daemon.enable = true;

  programs = {
    tmux.enable = true;
    zsh.enable = true;

    direnv = {
      enable = true;
      silent = true;
    };
  };

  environment.systemPackages = with pkgs; [
    # System utilities
    fzf
    htop
    jq
    ripgrep
    rsync

    # Development
    git
    gnumake
    go
    gotools
    neovim
    python3
    shellcheck

    # Media
    hugo
    yt-dlp

    # Networking
    curl
    ldns
    openssl
    whois
  ];

  networking = {
    computerName = "cooper";
    hostName = "cooper";
  };
}
