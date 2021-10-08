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

@test "should fit concat texts" {
  run util fit_concat nest "abc" "123"
  assert_output "abc ❱ 123"
}

@test "should truncate on insufficient space" {
  run util fit_concat nest "abc-def-ghi-jkl" "123"
  assert_output "abc-de ... kl ❱ 123"
}
