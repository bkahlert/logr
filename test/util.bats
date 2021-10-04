#!/usr/bin/env bats

setup() {
  load 'helpers/common.sh'
  load_lib support
  load_lib assert

  load "${BATS_CWD}/logr.sh"
}

@test "should print usage" {
  run util
  assert_line --partial "failed: util missing"
  assert_line --partial "Usage: util [-v|--var VAR] [-n|--newline] UTIL [ARGS...]"
}

@test "should print by default" {
  run util center "X"
  assert_output " X "
}

@test "should assign to variable if specified" {
  local var

  util -v var center "X"
  assert [ -z "${output:-}" ]
  assert_equal "${var:-}" " X "

  util --var var center "Y"
  assert [ -z "${output:-}" ]
  assert_equal "${var:-}" " Y "
}
