{ pkgs, ... }:

{
  programs.fish = {
    enable = true;

    interactiveShellInit = # fish
      ''
        set -gx EMAIL me@tomaskala.com
        set -gx EDITOR nvim

        set -gx XDG_CACHE_HOME ~/.cache
        set -gx XDG_CONFIG_HOME ~/.config
        set -gx XDG_DATA_HOME ~/.local/share

        set -gx GOPATH "$XDG_DATA_HOME/go"
        set -gx GOBIN ~/.local/bin
        set -gx GOTOOLCHAIN local

        set -g fish_greeting
        fish_add_path ~/.local/bin
      '';

    functions = {
      diff = "${pkgs.diffutils}/bin/diff -v diff --color=auto $argv";
      grep = "${pkgs.gnugrep}/bin/grep --color=auto $argv";
      ll = "ls -l $argv";
      lla = "ls -la $argv";
      ls = "${pkgs.coreutils}/bin/ls -FNh --color=auto --group-directories-first $argv";
      vim = "nvim $argv";
    };
  };
}
