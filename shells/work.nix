{ pkgs }:

let
  work = pkgs.writeShellApplication {
    name = "work";
    runtimeInputs = [ pkgs.yarn ];
    text = ''
      die() {
        printf '%s\n' "$1" >&2 && exit 1
      }

      if [ "$#" -eq 0 ]; then
        die 'No arguments provided'
      fi

      cmd="$1"
      shift

      case "$cmd" in
        fmt)
          yarn biome check --write --javascript-linter-enabled=false "$@"
          ;;
        test)
          yarn nx test "$@"
          ;;
        *)
          die "Unrecognized command: $cmd"
          ;;
      esac
    '';
  };
in pkgs.mkShell {
  name = "shell-work";

  packages = with pkgs; [
    # NodeJS development
    biome
    nodejs_18
    typescript
    yarn

    # My utilities
    work
  ];
}
