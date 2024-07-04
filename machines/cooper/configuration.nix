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
    lua
    python3
    shellcheck
    unstable.neovim

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
