#!/usr/bin/env bats

setup() {
  load "$BATS_CWD/logr.sh"
}

@test "should print usage" {
  run util
  assert_line --partial "command missing"
  assert_line --partial "Usage: util [-v VAR] UTIL [ARGS...]"
}

@test "should print by default" {
  run util center "X"
  assert_output " X "
}

@test "should assign to variable if specified" {
  local var
  util -v var center "X"
  assert [ ! "${output-}" ]
  assert_equal "${var-}" " X "
}
