{ lib, pkgs, ... }:

{
  programs.waybar = {
    enable = true;

    systemd = { enable = true; };

    settings = [{
      exclusive = true;
      position = "top";
      layer = "top";
      height = 18;
      passthrough = false;
      gtk-layer-shell = true;

      modules-left = [ "hyprland/workspaces" ];
      modules-center = [ "clock" "idle_inhibitor" ];
      modules-right = [
        "network"
        "battery"
        "wireplumber"
        "pulseaudio#source"
        "group/group-power"
      ];

      "hyprland/workspaces" = {
        format = "{icon}";
        format-icons = {
          "1" = "1";
          "2" = "2";
          "3" = "3";
          "4" = "4";
          "5" = "5";
          "6" = "6";
          "7" = "7";
          "8" = "8";
        };
        on-click = "activate";
      };

      "network" = {
        format-wifi = "{essid} ";
        format-ethernet = "{ifname} ";
        format-disconnected = "";
        tooltip-format = "{ifname} / {essid} ({signalStrength}%) / {ipaddr}";
        max-length = 15;
        on-click =
          "${pkgs.alacritty}/bin/alacritty -e ${pkgs.networkmanager}/bin/nmtui";
      };

      "idle_inhibitor" = {
        format = "{icon}";
        format-icons = {
          activated = "";
          deactivated = "";
        };
      };

      "battery" = {
        states = {
          good = 95;
          warning = 20;
          critical = 10;
        };
        format = "{capacity}% {icon}";
        format-charging = "{capacity}% ";
        format-plugged = "";
        tooltip-format = "{time} ({capacity}%)";
        format-alt = "{time} {icon}";
        format-full = "";
        format-icons = [ "" "" "" "" "" ];
      };

      "group/group-power" = {
        orientation = "inherit";
        drawer = {
          transition-duration = 500;
          transition-left-to-right = false;
        };
        modules =
          [ "custom/power" "custom/quit" "custom/lock" "custom/reboot" ];
      };

      "custom/quit" = {
        format = "󰗼";
        on-click = "${pkgs.hyprland}/bin/hyprctl dispatch exit";
        tooltip = false;
      };

      "custom/lock" = {
        format = "󰍁";
        on-click = "${pkgs.hyprlock}/bin/hyprlock";
        tooltip = false;
      };

      "custom/reboot" = {
        format = "󰜉";
        on-click = "${pkgs.systemd}/bin/systemctl reboot";
        tooltip = false;
      };

      "custom/power" = {
        format = "";
        on-click = "${pkgs.systemd}/bin/systemctl poweroff";
        tooltip = false;
      };

      "clock" = { format = "{:%d %b %H:%M}"; };

      "wireplumber" = {
        format = "{volume}% {icon}";
        format-muted = "";
        on-click = "${lib.getExe pkgs.pavucontrol}";
        format-icons = [ "" "" "" ];
        tooltip-format = "{volume}% / {node_name}";
      };

      "pulseaudio#source" = {
        format = "{format_source}";
        format-source = "";
        format-source-muted = "";
        on-click = "${lib.getExe pkgs.pavucontrol}";
        tooltip-format = "{source_volume}% / {desc}";
      };
    }];
  };

  # This is a hack to ensure that hyprctl ends up in the PATH for the waybar service on hyprland
  systemd.user.services.waybar.Service.Environment =
    lib.mkForce "PATH=${lib.makeBinPath [ pkgs.hyprland ]}";
}
