{ pkgs, ... }:

{
  imports = [
    ./associations.nix
    ./ghostty.nix
    ./gtk.nix
    ./hyprland.nix
    ./hyprlock.nix
    ./mako.nix
    ./qt.nix
    ./rofi.nix
    ./swappy.nix
    ./waybar.nix
    ./zathura.nix
  ];

  config = {
    services = {
      avizo.enable = true;
      cliphist.enable = true;
      gnome-keyring.enable = true;
    };

    systemd.user.services.polkit-gnome-authentication-agent-1 = {
      Unit.Description = "polkit-gnome-authentication-agent-1";
      Install.WantedBy = [ "graphical-session.target" ];
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };

    home = {
      packages = with pkgs; [
        grim
        libnotify
        libva-utils
        loupe
        pamixer
        pavucontrol
        playerctl
        wdisplays
        wl-clipboard
        xdg-utils
      ];

      sessionVariables = {
        _JAVA_AWT_WM_NONREPARENTING = "1";
        CLUTTER_BACKEND = "wayland";
        GDK_BACKEND = "wayland";
        MOZ_ENABLE_WAYLAND = "1";
        QT_QPA_PLATFORM = "wayland";
        QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
        SDL_VIDEODRIVER = "wayland";
        XDG_SESSION_TYPE = "wayland";
      };
    };
  };
}
