{ pkgs, ... }:

{
  home.packages = [ pkgs.swappy ];

  home.file.".config/swappy/config".text = # ini
    ''
      [Default]
      save_dir=$HOME/Pictures/screenshots
      save_filename_format=screenshot-%Y%m%d-%H%M%S.png
      early_exit=true
    '';
}
