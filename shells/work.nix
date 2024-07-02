{ pkgs }:

pkgs.mkShell {
  name = "shell-work";
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
