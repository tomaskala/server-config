{ lib, pkgs, ... }:

{
  programs.alacritty = {
    enable = true;

    settings = {
      env.TERM = "alacritty";
      live_config_reload = true;
      scrolling.history = 100000;

      shell.program = lib.getExe pkgs.fish;

      window.padding = {
        x = 20;
        y = 20;
      };

      font = {
        normal.family = "FiraCode NerdFont Mono";
        size = 14;
      };
    };
  };
}
