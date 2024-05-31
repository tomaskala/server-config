{ runCommand, nixfmt-classic }:

runCommand "check-statix" { nativeBuildInputs = [ nixfmt-classic ]; } ''
  set -e
  find ${./..} -type f -name '*.nix' -exec nixfmt --check {} \+
  touch $out
''
