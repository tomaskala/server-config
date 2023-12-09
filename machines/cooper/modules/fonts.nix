{ pkgs, ... }:

{
  fonts = {
    packages = with pkgs; [
      jetbrains-mono
      (nerdfonts.override { fonts = [ "NerdFontsSymbolsOnly" ]; })
      noto-fonts
      noto-fonts-color-emoji
      ttf_bitstream_vera
    ];

    fontconfig = {
      enable = true;
      includeUserConf = true;
    };
  };
}
