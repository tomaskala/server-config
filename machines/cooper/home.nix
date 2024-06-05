{ config, ... }:

{
  home-manager = {
    useGlobalPkgs = true;

    users.tomas = { home.stateVersion = config.system.stateVersion; };
  };
}
