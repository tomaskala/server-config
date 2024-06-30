{ runCommandLocal, deadnix }:

runCommandLocal "check-deadnix" { nativeBuildInputs = [ deadnix ]; } ''
  set -e
  deadnix --fail ${./..}
  touch $out
''
