{
  programs.yt-dlp = {
    enable = true;

    settings = {
      mtime = false;
      restrict-filenames = true;
      format = "bestvideo[height<=1080]+bestaudio/best[height<=1080]";
      merge-output-format = "mkv";
    };
  };
}
