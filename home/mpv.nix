{
  programs.mpv = {
    enable = true;

    bindings = {
      "h" = "seek -5; show_progress";
      "j" = "seek -60; show_progress";
      "k" = "seek 60; show_progress";
      "l" = "seek 5; show_progress";
      "S" = "cycle sub";
      "t" = "show_progress";
      "9" = "add volume -5";
      "0" = "add volume 5";
    };

    config = {
      "osd-font-size" = 32;
      "osd-bar-h" = 1;
      "osd-bar-w" = 100;
      "osd-bar-align-y" = 1;
      "af" = "scaletempo";
      "geometry" = "50%:50%";
      "script-opts-append" = "ytdl_hook-ytdl_path=yt-dlp";
      "ytdl-format" =
        "bestvideo[height<=?720][vcodec!=?vp9]+bestaudio/best[height<=?720]";
    };
  };
}
