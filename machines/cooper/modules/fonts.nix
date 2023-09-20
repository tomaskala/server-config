{ pkgs, ... }:

{
  fonts = {
    fonts = with pkgs; [
      jetbrains-mono
      (nerdfonts.override { fonts = [ "NerdFontsSymbolsOnly" ]; })
      noto-fonts
      noto-fonts-emoji
      ttf_bitstream_vera
    ];

    fontconfig = {
      enable = true;
      includeUserConf = true;
    };
  };
}
