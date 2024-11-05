{ pkgs, ... }:

{
  imports = [
    ../../home/fish.nix
    ../../home/git.nix
    ../../home/mpv.nix
    ../../home/neovim.nix
    ../../home/programs.nix
    ../../home/ssh.nix
    ../../home/starship.nix
    ../../home/tmux.nix
    ../../home/yt-dlp.nix
    ../../intranet
  ];

  config = {
    nix.package = pkgs.nix;

    home = {
      stateVersion = "24.05";
      username = "tomas";
      homeDirectory = "/home/tomas";
    };
  };
}
