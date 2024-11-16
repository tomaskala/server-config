{ lib, ... }:

{
  programs = {
    bat = {
      enable = true;
      config.theme = lib.mkDefault "ansi";
    };

    fd.enable = true;
    fzf.enable = true;
    home-manager.enable = true;
    htop.enable = true;
    jq.enable = true;
    ripgrep.enable = true;
  };
}
