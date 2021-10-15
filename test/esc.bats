#!/usr/bin/env bats

setup() {
  load 'helpers/common.sh'
  load_lib support
  load_lib assert

  load "$BATS_CWD/logr.sh"
}

@test "should print on empty list" {
  run esc
  assert_success
  assert [ ! "${output-}" ]
}

@test "should print ignore unknown capabilities" {
  run esc foo bar
  assert_success
  assert [ ! "${output-}" ]
}
