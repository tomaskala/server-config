{
  home-manager.users.root = {
    home.stateVersion = "23.05";

    programs.home-manager.enable = true;

    programs.ssh = {
      enable = true;

      matchBlocks = {
        "github.com" = {
          identityFile = "~/.ssh/id_ed25519_github";
          identitiesOnly = true;
        };
      };
    };
  };
}
