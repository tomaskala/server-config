{ lib, pkgs, ... }:

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

  config = {
    nix.package = pkgs.nix;

    programs.zsh.enable = true;

    home = {
      stateVersion = "24.05";
      username = "tomas";
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
        wineWowPackages.stable

        # Networking
        curl
        ldns
        rsync
        wireguard-tools

        # Fonts
        (nerdfonts.override { fonts = [ "FiraCode" ]; })
      ];
    };

    fonts.fontconfig.enable = true;

    catppuccin = {
      enable = true;
      accent = "mauve";
      flavor = "macchiato";
    };

    # Catppuccin for GTK has been discontinued.
    catppuccin.gtk.enable = lib.mkForce false;
  };
}
