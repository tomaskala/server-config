{ config, ... }:

{
  home-manager = {
    useGlobalPkgs = true;

    users.root = {
      home.stateVersion = config.system.stateVersion;

      programs.ssh = {
        enable = true;

        matchBlocks = {
          "github.com" = {
            identityFile = "/root/.ssh/id_ed25519_github";
            identitiesOnly = true;
          };
        };
      };
    };
  };
}
