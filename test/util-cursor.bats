#!/usr/bin/env bats

setup() {
  load 'helpers/common.sh'
  load_lib support
  load_lib assert

  load "$BATS_CWD/logr.sh"
}

@test "should print usage" {
  run util cursor
  assert_line --partial "failed: command missing"
  assert_line --partial "Usage: util [-v VAR] [-n|--newline] cursor show | hide"
}

@test "should show cursor" {
  run util cursor show
  trace
  [ ! "${output-}" ]
}

@test "should hide cursor" {
  run util cursor hide
  trace
  [ ! "${output-}" ]
}
