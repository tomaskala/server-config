{
  config = {
    home = {
      stateVersion = "23.05";
      homeDirectory = "/root";
    };

    programs = {
      home-manager.enable = true;

      ssh = {
        enable = true;

        matchBlocks = {
          "github.com" = {
            identitiesOnly = true;
            identityFile = "~/.ssh/id_ed25519_github";
          };
        };
      };
    };
  };
}
