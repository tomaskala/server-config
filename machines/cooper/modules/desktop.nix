{ lib, pkgs, ... }:

let
  hypr-run = pkgs.writeShellApplication {
    name = "hypr-run";
    runtimeInputs = [ pkgs.hyprland ];
    text = ''
      export XDG_SESSION_TYPE="wayland"
      export XDG_SESSION_DESKTOP="Hyprland"
      export XDG_CURRENT_DESKTOP="Hyprland"

      systemd-run --user --scope --collect --quiet --unit="hyprland" \
          systemd-cat --identifier="hyprland" Hyprland $@

      hyprctl dispatch exit
    '';
  };
in {
  programs = {
    dconf.enable = true;
    file-roller.enable = true;
    hyprland.enable = true;
  };

  environment = {
    variables.NIXOS_OZONE_WL = "1";

    systemPackages = with pkgs; [
      nautilus
      zenity
      # Enable HEIC image previews in Nautilus.
      libheif
      libheif.out
      polkit_gnome
    ];

    # Enable HEIC image previews in Nautilus.
    pathsToLink = [ "share/thumbnailers" ];
  };

  services = {
    dbus = {
      enable = true;
      implementation = "broker";
    };

    gnome = {
      gnome-keyring.enable = true;
      sushi.enable = true;
    };

    greetd = {
      enable = true;
      settings.default_session.command = ''
        ${
          lib.makeBinPath [ pkgs.greetd.tuigreet ]
        }/tuigreet -r --asterisks --time --cmd ${lib.getExe hypr-run}
      '';
    };
  };
}
