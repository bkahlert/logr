#!/usr/bin/env bats

setup() {
  load 'helpers/common.sh'
  load_lib support
  load_lib assert

  load "$BATS_CWD/logr.sh"
}

@test "should print usage" {
  run tty cursor
  assert_line --partial "failed: command missing"
  assert_line --partial "Usage: tty [-v VAR] cursor show | hide"
}

@test "should show cursor" {
  run tty cursor show
  [ ! "${output-}" ]
}

@test "should hide cursor" {
  run tty cursor hide
  [ ! "${output-}" ]
}
