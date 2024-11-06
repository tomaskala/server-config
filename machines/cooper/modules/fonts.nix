{ pkgs, ... }:

{
  fonts = {
    packages = with pkgs; [
      (nerdfonts.override { fonts = [ "FiraCode" ]; })
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
