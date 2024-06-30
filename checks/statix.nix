{ runCommandLocal, statix }:

runCommandLocal "check-statix" { nativeBuildInputs = [ statix ]; } ''
  set -e
  statix check ${./..}
  touch $out
''
