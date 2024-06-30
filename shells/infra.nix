{ pkgs }:

pkgs.mkShell {
  name = "infra-shell";
  packages = with pkgs; [ deadnix nixfmt-classic statix ];
}
