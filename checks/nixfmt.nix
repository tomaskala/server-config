{ runCommand, nixfmt }:

runCommand "check-statix" { nativeBuildInputs = [ nixfmt ]; } ''
  set -e
  find ${./..} -type f -name '*.nix' -exec nixfmt --check {} \+
  touch $out
''
