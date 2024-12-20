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

        "$fill"

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
        read_only = " 󰌾";
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
    };
  };
}
