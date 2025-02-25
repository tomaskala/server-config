{
  programs.git = {
    enable = true;
    lfs.enable = true;

    delta = {
      enable = true;
      options = {
        hunk-header-style = "file syntax";
        line-numbers = true;
        syntax-theme = "ansi";
      };
    };

    extraConfig = {
      user = {
        name = "Tomas Kala";
        email = "me@tomaskala.com";
      };

      init.defaultBranch = "main";
      fetch.prune = true;
      pull.ff = "only";

      push = {
        autoSetupRemote = true;
        followTags = true;
      };

      rebase = {
        autoSquash = true;
        autoStash = true;
      };

      merge = {
        ff = "only";
        conflictStyle = "zdiff3";
      };

      diff.algorithm = "histogram";
      branch.sort = "-committerdate";
      tag.sort = "version:refname";
    };
  };
}
