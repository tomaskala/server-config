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
      accent = "mauve";
      flavor = "macchiato";
      enable = true;
    };

    # Catppuccin for GTK has been discontinued.
    gtk.catppuccin.enable = lib.mkForce false;
  };
}
