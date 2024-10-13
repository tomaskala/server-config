{
  programs.git = {
    enable = true;
    lfs.enable = true;

    extraConfig = {
      user = {
        name = "Tomas Kala";
        email = "me@tomaskala.com";
      };

      init.defaultBranch = "master";
      fetch.prune = true;
      pull.ff = "only";

      rebase = {
        autoSquash = true;
        autoStash = true;
      };

      merge = {
        ff = "only";
        conflictStyle = "zdiff3";
      };

      diff.algorithm = "histogram";
    };
  };
}
