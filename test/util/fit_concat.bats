#!/usr/bin/env bats

setup() {
  load "$BATS_CWD/logr.sh"
  export COLUMNS=20
}

teardown() {
  export -n COLUMNS
}

@test "should fit concat texts" {
  run util fit_concat nested "abc" "123"
  assert_output "abc ❱ 123"
}

@test "should truncate on insufficient space" {
  run util fit_concat nested "abc-def-ghi-jkl" "123"
  assert_output "abc-def ... l ❱ 123"
}
