{ pkgs }:

pkgs.mkShell {
  name = "work-shell";
  packages = with pkgs; [
    # NodeJS development
    biome
    nodejs_18
    typescript
    yarn

    # Python development
    python3
    poetry
  ];
}
