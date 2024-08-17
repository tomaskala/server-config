{ pkgs, ... }:

let username = "tomas";
in {
  home = {
    # TODO: The following 3 options should be provided from flake.nix.
    inherit username;
    homeDirectory = if pkgs.stdenv.isDarwin then
      "/Users/${username}"
    else
      "/home/${username}";
    stateVersion = "24.05";

    sessionPath = [ "$HOME/.local/bin" ];

    sessionVariables = {
      EMAIL = "me@tomaskala.com";
      SSH_AUTH_SOCK = ''"$XDG_RUNTIME_DIR/ssh-agent.socket"'';
      GOTOOLCHAIN = "local";
    };

    shellAliases = {
      "diff" = "'diff --color=auto'";
      "grep" = "'grep --color=auto'";
      "ls" = "'ls -FNh --color=auto --group-directories-first'";
      "ll" = "'ls -l'";
      "lla" = "'ls -la'";
      "ya" = "'mpv --no-video --ytdl-format=bestaudio'";
    };
  };
}
