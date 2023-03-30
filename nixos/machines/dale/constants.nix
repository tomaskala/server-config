{ ... }:

rec {
  domain = "tomaskala.com";
  email.acme = "public@${domain}";
  wanInterface = "venet0";
}
