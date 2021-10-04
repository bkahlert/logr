#!/usr/bin/env bats

setup() {
  load 'helpers/common.sh'
  load_lib support
  load_lib assert

  load "${BATS_CWD}/logr.sh"
}

@test "should print" {
  run logr info foo
  assert_output " ℹ foo"
}

@test "should empty" {
  run logr info
  assert_output " ℹ "
}

@test "should print array" {
  run logr info foo bar
  assert_output " ℹ foo bar"
}
