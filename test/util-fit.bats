#!/usr/bin/env bats

setup() {
  load 'helpers/common.sh'
  load_lib support
  load_lib assert

  load "${BATS_CWD}/logr.sh"
  export COLUMNS=20
}

teardown() {
  export -n COLUMNS
}

@test "should fit text" {
  run util fit "123456789012345678901234567890"
  assert_output "123456 ... 567890"
}

@test "should trim inner blanks" {
  run util fit "   12                          90   "
  assert_output "   12 ... 90   "
}

@test "should do nothing if enough space" {
  run util fit "123"
  assert_output "123"
}
