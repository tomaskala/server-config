{ lib, pkgs, ... }:

{
  home-manager.users.tomas = {
    home.stateVersion = "24.05";

    programs = {
      home-manager.enable = true;

      fzf.enable = true;
      htop.enable = true;
      jq.enable = true;
      ripgrep.enable = true;

      yt-dlp = {
        enable = true;

        settings = {
          mtime = false;
          restrict-filenames = true;
          format = "bestvideo[height<=1080]+bestaudio/best[height<=1080]";
          merge-output-format = "mkv";
        };
      };

      fish = {
        enable = true;

        interactiveShellInit = ''
          set -gx EMAIL me@tomaskala.com
          set -gx EDITOR nvim
          set -gx SSH_AUTH_SOCK ~/.ssh/agent.sock

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
          diff = "diff --color=auto $argv";
          grep = "grep --color=auto $argv";
          ll = "ls -l $argv";
          lla = "ls -la $argv";
          ls =
            "${pkgs.coreutils}/bin/ls -FNh --color=auto --group-directories-first $argv";
          vim = "nvim $argv";
          ya = "mpv --no-video --ytdl-format=bestaudio $argv";
        };
      };

      starship = {
        enable = true;

        settings = {
          format = lib.concatStrings [
            "$username"
            "$hostname"
            "$directory"
            "$git_branch"
            "$git_state"
            "$git_status"
            "$fill"

            "$c"
            "$docker_context"
            "$fennel"
            "$golang"
            "$haskell"
            "$lua"
            "$nodejs"
            "$python"

            "$status"
            "$line_break"
            "$character"
          ];

          fill.symbol = " ";
          hostname.ssh_symbol = "";
          status.disabled = false;
          username.format = "[$user]($style)@";

          character = {
            success_symbol = "[❯](purple)";
            error_symbol = "[❯](red)";
            vimcmd_symbol = "[❯](green)";
          };

          directory = {
            style = "blue";
            truncate_to_repo = false;
            truncation_length = 5;
            truncation_symbol = ".../";
          };

          git_branch = {
            symbol = " ";
            format = "[$symbol $branch]($style)";
            style = "green";
          };

          git_status = {
            format =
              "[[( $conflicted$untracked$modified$staged$renamed$deleted)](218) ($ahead_behind$stashed)]($style)";
            style = "cyan";
            conflicted = "=$count ";
            untracked = "?$count ";
            modified = "!$count ";
            staged = "+$count ";
            renamed = "»$count ";
            deleted = "✘$count ";
            stashed = "≡";
          };

          git_state = {
            format = "([$state( $progress_current/$progress_total)]($style)) ";
            style = "bright-black";
          };

          c.symbol = " ";
          directory.read_only = " 󰌾";
          docker_context.symbol = " ";
          fennel.symbol = " ";
          golang.symbol = " ";
          haskell.symbol = " ";
          lua.symbol = " ";
          nix_shell.symbol = " ";
          nodejs.symbol = " ";
          package.symbol = "󰏗 ";
          python.symbol = " ";
        };
      };

      git = {
        enable = true;
        lfs.enable = true;

        extraConfig = {
          user = {
            name = "Tomas Kala";
            email = "me@tomaskala.com";
          };

          init.defaultBranch = "master";
          fetch.prune = true;
          pull.ff = "only";

          rebase = {
            autoSquash = true;
            autoStash = true;
          };

          merge = {
            ff = "only";
            conflictStyle = "zdiff3";
          };

          diff.algorithm = "histogram";
        };

        includes = [{
          condition = "gitdir:~/IPFabric/";
          contents.user.email = "tomas.kala@ipfabric.io";
        }];
      };

      tmux = {
        enable = true;
        baseIndex = 1;
        clock24 = true;
        keyMode = "vi";
        mouse = true;
        prefix = "C-s";
        sensibleOnTop = true;

        extraConfig = ''
          set -g  renumber-windows on
          set -gw automatic-rename on
          set -g bell-action none

          bind - split-window -v -c "#{pane_current_path}"
          bind | split-window -h -c "#{pane_current_path}"
        '';
      };
    };
  };
}
