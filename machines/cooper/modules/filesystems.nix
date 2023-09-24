{ pkgs, ... }:

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

    "/persistent" = {
      fsType = "btrfs";
      options = [ "subvol=persistent" "compress=zstd" ];
      neededForBoot = true;
    };
  };

  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" ];
  };

  # TODO: The encrypted device must be named 'crypt'.
  # TODO: Is the recursive deletion necessary for a flat structure?
  boot.initrd.systemd.services.rollback = {
    description = "Rollback btrfs root subvolume to a pristine state";

    wantedBy = [ "initrd.target" ];
    after = [ "systemd-cryptsetup@crypt.service" ];
    before = [ "sysroot.mount" ];

    unitConfig.DefaultDependencies = false;
    serviceConfig.Type = "oneshot";

    script = ''
      mkdir -p /mnt
      mount -o subvol=/ /dev/mapper/crypt /mnt

      delete_subvolume_recursively() {
        local IFS=$'\n'
        local subvolume

        for subvolume in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
          delete_subvolume_recursively "/mnt/$subvolume"
        done

        printf 'Deleting subvolume %s\n' "$1"
        btrfs subvolume delete "$1"
      }

      printf 'Recursively deleting the root subvolume\n'
      delete_subvolume_recursively /mnt/root

      printf 'Restoring a blank root subvolume\n'
      btrfs subvolume create /mnt/root

      umount /mnt
    '';
  };

  environment = {
    systemPackages = [ pkgs.btrfs-progs ];

    persistence."/persistent" = {
      hideMounts = true;

      directories = [
        "/etc/nixos"
        "/var/lib/fwupd"
        "/var/lib/nixos"
        "/var/lib/systemd/coredump"
        "/var/log"
      ];

      files = [ "/etc/machine-id" "/root/.bash_history" ];

      users.tomas = {
        directories = [
          ".cache/nix"
          ".config/discord"
          ".config/fontconfig"
          ".config/git"
          ".config/lynx"
          ".config/mbsync"
          ".config/mpd"
          ".config/mpv"
          ".config/msmtp"
          ".config/mutt"
          ".config/mvi"
          ".config/tmux"
          ".config/yt-dlp"
          ".config/zathura"
          ".emacs.d"
          ".local/bin"
          ".local/share/password-store"
          ".local/share/wallpaper"
          ".local/share/zathura"
          ".mozilla"
          "Documents"
          "Downloads"
          "Mail"
          "Notes"
          "Pictures"
          "Repos"
          {
            directory = ".gnupg";
            mode = "0700";
          }
          {
            directory = ".ssh";
            mode = "0700";
          }
        ];

        files = [
          ".bash_history"
          ".bash_profile"
          ".bash_profile_local"
          ".bashrc"
          ".config/inputrc"
          ".config/user-dirs.conf"
          ".vimrc"
        ];
      };
    };
  };
}
