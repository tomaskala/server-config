{ runCommand, deadnix }:

runCommand "check-deadnix" { nativeBuildInputs = [ deadnix ]; } ''
  set -e
  deadnix --fail ${./..}
  touch $out
''
