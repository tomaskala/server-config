{ lib, pkgs, ... }:

let
  text = "#cad3f5";
  subtext = "#b8c0e0";
  dark = "#1e2030";
  bg = "#24273a";

  black = "#181926";
  purple = "#c6a0f6";
in {
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        grace = 5;
        hide_cursor = true;
      };

      background = [{ color = bg; }];

      input-field = [{
        size = "250, 60";
        outer_color = "rgb(${black})";
        inner_color = "rgb(${dark})";
        font_color = "rgb(${purple})";
        placeholder_text = "";
      }];

      label = [
        {
          text = "Hello, friend";
          color = "rgba(${text}, 1.0)";
          font_size = 64;
          text_align = "center";
          halign = "center";
          valign = "center";
          position = "0, 160";
        }
        {
          text = "$TIME";
          color = "rgba(${subtext}, 1.0)";
          font_size = 32;
          text_align = "center";
          halign = "center";
          valign = "center";
          position = "0, 75";
        }
      ];
    };
  };

  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "${lib.getExe pkgs.hyprlock}";
        before_sleep_cmd = "${lib.getExe pkgs.hyprlock}";
      };

      listener = [
        {
          timeout = 300;
          on-timeout = "${lib.getExe pkgs.hyprlock}";
        }
        {
          timeout = 305;
          on-timeout = "${pkgs.hyprland}/bin/hyprctl dispatch dpms off";
          on-resume = "${pkgs.hyprland}/bin/hyprctl dispatch dpms on";
        }
      ];
    };
  };
}
