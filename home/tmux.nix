{
  programs.tmux = {
    enable = true;
    baseIndex = 1;
    clock24 = true;
    keyMode = "vi";
    mouse = true;
    prefix = "C-s";
    sensibleOnTop = true;

    extraConfig = # tmux
      ''
        set -g renumber-windows on
        set -gw automatic-rename on
        set -g bell-action none

        bind - split-window -v -c "#{pane_current_path}"
        bind | split-window -h -c "#{pane_current_path}"
      '';
  };
}
