{ pkgs, ... }:

{
  imports = [
    ../../home/fish.nix
    ../../home/git.nix
    ../../home/mpv.nix
    ../../home/neovim.nix
    ../../home/programs.nix
    ../../home/ssh.nix
    ../../home/starship.nix
    ../../home/tmux.nix
    ../../home/yt-dlp.nix
    ../../intranet
  ];

  config.home = {
    stateVersion = "24.05";
    homeDirectory = "/home/tomas";

    packages = with pkgs; [
      # Development
      go
      gotools
      lua
      python3
      shellcheck

      # Media
      hugo

      # Networking
      ldns
    ];
  };
}
