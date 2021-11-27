#!/usr/bin/env bats

setup() {
  load helpers/common.sh
  load_lib support
  load_lib assert
  load_lib file
  cd "$BATS_TEST_TMPDIR" || exit 1
}

@test "should run specified command" {
  TMPDIR="${BATS_TEST_TMPDIR%/}/tmp" source "$BATS_CWD/logr.sh"
  [ -d "tmp" ]
}
