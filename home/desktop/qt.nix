{ pkgs, ... }:

{
  qt = {
    enable = true;
    platformTheme.name = "gtk";
  };

  home = {
    packages = [ pkgs.libsForQt5.qtstyleplugin-kvantum ];
    sessionVariables = { "QT_STYLE_OVERRIDE" = "kvantum"; };
  };
}
