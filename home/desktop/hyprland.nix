{ pkgs, ... }:

{
  home.packages = [ pkgs.grimblast ];

  wayland.windowManager.hyprland = {
    enable = true;

    settings = {
      "$mod" = "SUPER";

      monitor = [ "eDP-1, preferred, auto, 1.5" ];

      windowrulev2 = [
        # Only allow shadows for floating windows.
        "noshadow, floating:0"

        # Idle inhibit while watching videos.
        "idleinhibit focus, class:^(mpv|.+exe)$"
        "idleinhibit fullscreen, class:.*"

        # Make Firefox PiP window floating and sticky.
        "float, title:^(Picture-in-Picture)$"
        "pin, title:^(Picture-in-Picture)$"

        "float, class:^(org.gnome.*)$"
        "float, class:^(pavucontrol)$"

        # Make pop-up file dialogs floating, centred, and pinned.
        "float, title:(Open|Progress|Save File)"
        "center, title:(Open|Progress|Save File)"
        "pin, title:(Open|Progress|Save File)"

        # Throw sharing indicators away.
        "workspace special silent, title:^(Firefox — Sharing Indicator)$"
        "workspace special silent, title:^(.*is sharing (your screen|a window)\\.)$"
      ];

      general = {
        gaps_in = 4;
        gaps_out = 8;
        border_size = 0;
      };

      input = {
        follow_mouse = 2;
        repeat_rate = 50;
        repeat_delay = 300;
      };

      decoration = { rounding = 8; };

      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
      };
    };

    extraConfig = ''
      # terminal, screen locking, launcher
      bind = $mod, RETURN, exec, alacritty
      bind = $mod, X, exec, hyprlock
      bind = $mod, SPACE, exec, rofi -show drun
      bind = ALT, Q, killactive,

      # screenshots
      $screenshotarea = hyprctl keyword animation "fadeOut,0,0,default"; grimblast save area - | swappy -f -; hyprctl keyword animation "fadeOut,1,4,default"
      bind = , Print, exec, grimblast save output - | swappy -f -
      bind = SHIFT, Print, exec, grimblast save active - | swappy -f -
      bind = ALT, Print, exec, $screenshotarea

      # media controls
      bindl = , XF86AudioPlay, exec, playerctl play-pause
      bindl = , XF86AudioPrev, exec, playerctl previous
      bindl = , XF86AudioNext, exec, playerctl next

      # volume
      bindle = , XF86AudioRaiseVolume, exec, volumectl -u up
      bindle = , XF86AudioLowerVolume, exec, volumectl -u down
      bindl = , XF86AudioMute, exec, volumectl -u toggle-mute
      bindl = , XF86AudioMicMute, exec, volumectl -m toggle-mute
      bindl = , Pause, exec, volumectl -m toggle-mute

      # backlight
      bindle = , XF86MonBrightnessUp, exec, lightctl up
      bindle = , XF86MonBrightnessDown, exec, lightctl down

      # clipboard
      bind = $mod, C, exec, bash -c "export XDG_CACHE_HOME=/home/$USER/.local/cache; cliphist list | rofi -dmenu -display-columns 2 -window-title "📋" | cliphist decode | wl-copy"

      # apps
      bind = $mod, E, exec, bemoji -c -n

      # window controls
      bind = $mod, F, fullscreen,
      bind = $mod SHIFT, Space, togglefloating,
      bind = $mod, A, togglesplit,

      # override the split direction for the next window to be opened
      bind = $mod, V, layoutmsg, preselect d
      bind = $mod, B, layoutmsg, preselect r

      # group management
      bind = $mod, G, togglegroup,
      bind = $mod SHIFT, G, moveoutofgroup,
      bind = ALT, left, changegroupactive, b
      bind = ALT, right, changegroupactive, f

      # move focus
      bind = $mod, H, movefocus, l
      bind = $mod, L, movefocus, r
      bind = $mod, K, movefocus, u
      bind = $mod, J, movefocus, d

      # move window
      bind = $mod SHIFT, H, movewindoworgroup, l
      bind = $mod SHIFT, L, movewindoworgroup, r
      bind = $mod SHIFT, K, movewindoworgroup, u
      bind = $mod SHIFT, J, movewindoworgroup, d

      # window resize
      bind = $mod, R, submap, resize
      submap = resize
      binde = , right, resizeactive, 10 0
      binde = , left, resizeactive, -10 0
      binde = , up, resizeactive, 0 -10
      binde = , down, resizeactive, 0 10
      bind = , escape, submap, reset
      submap = reset

      # mouse bindings
      bindm = SUPER, mouse:272, movewindow
      bindm = SUPER, mouse:273, resizewindow

      # navigate workspaces
      bind = $mod, 1, workspace, 1
      bind = $mod, 2, workspace, 2
      bind = $mod, 3, workspace, 3
      bind = $mod, 4, workspace, 4
      bind = $mod, 5, workspace, 5
      bind = $mod, 6, workspace, 6
      bind = $mod, 7, workspace, 7
      bind = $mod, 8, workspace, 8
      bind = $mod, 9, workspace, 9

      # move window to workspace
      bind = $mod SHIFT, 1, movetoworkspace, 1
      bind = $mod SHIFT, 2, movetoworkspace, 2
      bind = $mod SHIFT, 3, movetoworkspace, 3
      bind = $mod SHIFT, 4, movetoworkspace, 4
      bind = $mod SHIFT, 5, movetoworkspace, 5
      bind = $mod SHIFT, 6, movetoworkspace, 6
      bind = $mod SHIFT, 7, movetoworkspace, 7
      bind = $mod SHIFT, 8, movetoworkspace, 8
      bind = $mod SHIFT, 9, movetoworkspace, 9
    '';
  };
}
