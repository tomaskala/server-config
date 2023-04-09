{
  config = rec {
    domains = {
      public = "tomaskala.com";
      rss = "rss.home.arpa";
    };
    email.acme = "public@${domains.public}";
    wanInterface = "venet0";
  }
}
