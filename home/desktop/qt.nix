{ pkgs, ... }:

{
  qt = {
    enable = true;
    style.name = "kvantum";
    platformTheme.name = "kvantum";
  };

  home = {
    packages = [ pkgs.libsForQt5.qtstyleplugin-kvantum ];
    sessionVariables = { "QT_STYLE_OVERRIDE" = "kvantum"; };
  };
}
