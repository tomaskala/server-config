{
  fileSystems = {
    "/" = {
      fsType = "btrfs";
      options = [ "subvol=root" "compress=zstd" ];
    };

    "/home" = {
      fsType = "btrfs";
      options = [ "subvol=home" "compress=zstd" ];
    };

    "/nix" = {
      fsType = "btrfs";
      options = [ "subvol=nix" "compress=zstd" "noatime" ];
    };
  };

  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" ];
  };
}
