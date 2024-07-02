{ pkgs }:

pkgs.runCommandLocal "check-deadnix" {
  nativeBuildInputs = [ pkgs.deadnix ];
} ''
  set -e
  deadnix --fail ${./..}
  touch $out
''
