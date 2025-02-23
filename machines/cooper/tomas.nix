{ lib, pkgs, ... }:

{
  imports = [
    ../../home/desktop/ghostty.nix
    ../../home/desktop/zathura.nix
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
    };

    catppuccin = {
      enable = true;
      accent = "mauve";
      flavor = "macchiato";
    };

    # Catppuccin for GTK has been discontinued.
    gtk.catppuccin.enable = lib.mkForce false;

    xdg.desktopEntries.openmw = {
      name = "OpenMW";
      type = "Application";
      exec = "${pkgs.gamemode}/bin/gamemoderun ${pkgs.openmw}/bin/openmw-launcher";
      terminal = false;
      categories = [ "Game" ];
    };
  };
}
