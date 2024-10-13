{ lib, ... }:

{
  programs.starship = {
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
}
