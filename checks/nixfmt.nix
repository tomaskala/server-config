{ pkgs }:

pkgs.runCommandLocal "check-nixfmt" { nativeBuildInputs = [ pkgs.nixfmt-rfc-style ]; } ''
  set -e
  find ${./..} -type f -name '*.nix' -exec nixfmt --check {} \+
  touch $out
''
