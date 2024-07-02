{ pkgs }:

pkgs.runCommandLocal "check-statix" { nativeBuildInputs = [ pkgs.statix ]; } ''
  set -e
  statix check ${./..}
  touch $out
''
