{ pkgs }:

pkgs.mkShell {
  name = "shell-infra";
  packages = with pkgs; [ deadnix nixfmt-rfc-style statix ];
}
