{ runCommand, statix }:

runCommand "check-statix" { nativeBuildInputs = [ statix ]; } ''
  set -e
  statix check ${./..}
  touch $out
''
