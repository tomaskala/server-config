{ config }:

let
  inherit (config.lib.formats.rasi) mkLiteral;

  bg = "#24273a";
  text = "#cad3f5";
  accent = "#8aadf4";

  red = "#ed8796";
  green = "#a6da95";
  blue = "#7dc4e4";
  orange = "#f5a97f";
in
{
  "*" = {
    border = mkLiteral "none";
    padding = mkLiteral "0px";
    font-family = "Inter";
    font-size = mkLiteral "15px";
  };

  "window#waybar" = {
    background-color = mkLiteral "transparent";
  };

  "window>box" = {
    margin = mkLiteral "8px 8px 0px 8px";
    background = mkLiteral "${bg}";
    opacity = mkLiteral "0.8";
    border-radius = mkLiteral "8px";
  };

  ".modules-right" = {
    margin-right = mkLiteral "10px";
    padding = mkLiteral "5px 10px";
  };

  ".modules-center" = {
    margin = mkLiteral "0px";
    padding = mkLiteral "5px 10px";
  };

  ".modules-left" = {
    margin-left = mkLiteral "10px";
    padding = mkLiteral "5px 0px";
  };

  "#workspaces button" = {
    padding = mkLiteral "0px 10px";
    background-color = mkLiteral "transparent";
    font-weight = mkLiteral "lighter";
    color = mkLiteral "${text}";
  };

  "#workspaces button:hover" = {
    color = mkLiteral "${accent}";
    background-color = mkLiteral "transparent";
  };

  "#workspaces button.focused, #workspaces button.active" = {
    color = mkLiteral "${accent}";
    font-weight = mkLiteral "normal";
    background-color = mkLiteral "transparent";
  };

  "#battery,\n      #clock,\n      #cpu,\n      #custom-lock,\n      #custom-power,\n      #custom-quit,\n      #custom-reboot,\n      #custom-vpn,\n      #group-group-power,\n      #memory,\n      #network,\n      #pulseaudio,\n      #wireplumber" = {
    padding = mkLiteral "0px 10px";
    color = mkLiteral "${text}";
  };

  "#custom-vpn.tailnet" = {
    color = mkLiteral "${blue}";
    background-color = mkLiteral "transparent";
  };
  "#custom-vpn.exitNode" = {
    color = mkLiteral "${green}";
    background-color = mkLiteral "transparent";
  };
  "#custom-vpn.disconnected" = {
    color = mkLiteral "${red}";
    background-color = mkLiteral "transparent";
  };

  "#custom-power" = {
    color = mkLiteral "${accent}";
    background-color = mkLiteral "transparent";
  };

  "#custom-quit, #custom-lock, #custom-reboot" = {
    color = mkLiteral "${red}";
    background-color = mkLiteral "transparent";
  };

  # -----Indicators----
  "#battery.charging" = {
    color = mkLiteral "${green}";
  };

  "#battery.warning:not(.charging)" = {
    color = mkLiteral "${orange}";
  };

  "#battery.critical:not(.charging)" = {
    color = mkLiteral "${red}";
  };

  "#temperature.critical" = {
    color = mkLiteral "${red}";
  };

  "#wireplumber.muted" = {
    color = mkLiteral "${orange}";
  };

  "#pulseaudio.source-muted" = {
    color = mkLiteral "${orange}";
  };
}
