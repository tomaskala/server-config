{
  config = rec {
    domains = {
      public = "tomaskala.com";
    };
    email.acme = "public@${domains.public}";
    wanInterface = "venet0";
  };
}
