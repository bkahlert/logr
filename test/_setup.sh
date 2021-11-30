#!/usr/bin/env bash

# Creates a temporary file containing the specified lines and prints it path.
# If the first arguments is `+x` the file will be made executable.
# Arguments:
#   +x - optional flag set the executable flag on the returned file
#   -  - reads the lines from STDIN
#   *  - lines to add to the file
# Output:
#   STDOUT - path of the created file
mkfile() {
  local file
  file="$(mktemp "$BATS_TEST_TMPDIR/XXXXXX")"
  touch "$file"
  [ ! "${1-}" = '+x' ] || {
    chmod +x "$file" && shift
  }
  while(($#)); do
    case $1 in
    -)
      cat - >>"$file" && shift
      ;;
    *)
      printf '%s\n' "$1" >>"$file" && shift
      ;;
    esac
  done
  printf '%s\n' "$file"
}
