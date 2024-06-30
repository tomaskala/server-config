{ runCommandLocal, nixfmt-classic }:

runCommandLocal "check-nixfmt" { nativeBuildInputs = [ nixfmt-classic ]; } ''
  set -e
  find ${./..} -type f -name '*.nix' -exec nixfmt --check {} \+
  touch $out
''
