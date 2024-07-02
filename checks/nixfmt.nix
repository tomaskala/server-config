{ pkgs }:

pkgs.runCommandLocal "check-nixfmt" {
  nativeBuildInputs = [ pkgs.nixfmt-classic ];
} ''
  set -e
  find ${./..} -type f -name '*.nix' -exec nixfmt --check {} \+
  touch $out
''
