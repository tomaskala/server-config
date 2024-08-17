{
  programs.git.includes = [{
    condition = "gitdir:~/IPFabric/";

    contents = {
      user.email = "tomas.kala@ipfabric.io";
      init.defaultBranch = "main";
    };
  }];

  # TODO: Include work SSH hosts configuration.
}
