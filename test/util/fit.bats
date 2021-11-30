#!/usr/bin/env bats

setup() {
  load "$BATS_CWD/logr.sh"
  export COLUMNS=20
}

teardown() {
  export -n COLUMNS
}

@test "should fit text" {
  run util fit "123456789012345678901234567890"
  assert_output "1234567 ... 4567890"
}

@test "should trim inner blanks" {
  run util fit "   12                          90   "
  assert_output "   12  ...  90   "
}

@test "should do nothing if enough space" {
  run util fit "123"
  assert_output "123"
}

@test "should not truncate to less than 20 columns" {
  COLUMNS=10
  run util fit "12345678901234567890"
  assert_output "12345678901234567890"
}

@test "should reduce size at least by one if truncating" {
  run util fit "123456789012345678901"
  assert_output "1234567 ... 5678901"
}
