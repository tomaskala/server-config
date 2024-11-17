{ config, lib, pkgs, ... }:

let
  mkValueString = value:
    if lib.isBool value then
      if value then "true" else "false"
    else if lib.isInt value then
      builtins.toString value
    else if (value._type or "") == "literal" then
      value.value
    else if builtins.isString value then
      ''"${value}"''
    else if builtins.isList value then
      "[ ${builtins.concatStringsSep "," (map mkValueString value)} ]"
    else
      abort "Unhandled value type ${builtins.typeOf value}";

  mkKeyValue = { sep ? ": ", end ? ";", }:
    name: value:
    "${name}${sep}${mkValueString value}${end}";

  mkRasiSection = name: value:
    if builtins.isAttrs value then
      let
        toRasiKeyValue =
          lib.generators.toKeyValue { mkKeyValue = mkKeyValue { }; };
        # Remove null values so the resulting config does not have empty lines
        configStr =
          toRasiKeyValue (lib.attrsets.filterAttrs (_: v: v != null) value);
      in ''
        ${name} {
        ${configStr}}
      ''
    else
      (mkKeyValue {
        sep = " ";
        end = "";
      } name value) + "\n";

  toRasi = attrs:
    builtins.concatStringsSep "\n"
    (builtins.concatMap (lib.attrsets.mapAttrsToList mkRasiSection) [
      (lib.attrsets.filterAttrs (n: _: n == "@theme") attrs)
      (lib.attrsets.filterAttrs (n: _: n == "@import") attrs)
      (builtins.removeAttrs attrs [ "@theme" "@import" ])
    ]);

  tsCheck = pkgs.writeShellApplication {
    name = "tscheck";
    runtimeInputs = [ pkgs.jq pkgs.tailscale ];
    text = ''
      if [[ "$1" == "toggle" ]]; then
        if [[ "$(tailscale status --json | jq -r '.BackendState')" == "Stopped" ]]; then
          tailscale up --operator=tomas --reset
        else
          tailscale down
        fi
      fi

      if tailscale status &>/dev/null; then
        if [[ "$(tailscale status --json | jq -r '.ExitNodeStatus.Online')" == "true" ]]; then
          ip="$(tailscale status --json | jq -r '.ExitNodeStatus.TailscaleIPs[0]')"
          echo "{\"text\": \"󰖂\", \"tooltip\": \"Connected to exit node ($ip)\", \"class\": \"exitNode\"}" | jq --unbuffered --compact-output
        else
          echo "{\"text\": \"󰖂\", \"tooltip\": \"Connected to tailnet\", \"class\": \"tailnet\"}" | jq --unbuffered --compact-output
        fi
      else
        echo '{"text": "󰖂", "tooltip": "Disconnected", "class": "disconnected"}' | jq --unbuffered --compact-output
      fi
    '';
  };
in {
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
      modules-center = [ "clock" ];
      modules-right = [
        "network"
        "battery"
        "custom/vpn"
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

      "custom/vpn" = {
        format = "{}";
        exec = "${lib.getExe tsCheck} status";
        on-click = "${lib.getExe tsCheck} toggle";
        return-type = "json";
        interval = 1;
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

    style = toRasi (import ./waybar-theme.nix { inherit config; });
  };

  # This is a hack to ensure that hyprctl ends up in the PATH for the waybar service on hyprland
  systemd.user.services.waybar.Service.Environment =
    lib.mkForce "PATH=${lib.makeBinPath [ pkgs.hyprland ]}";
}
