{ pkgs, ... }:

{
  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-color-emoji
      ttf_bitstream_vera
      inter
    ];

    fontconfig = {
      enable = true;
      includeUserConf = true;
    };
  };
}
