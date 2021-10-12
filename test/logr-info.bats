#!/usr/bin/env bats

setup() {
  load 'helpers/common.sh'
  load_lib support
  load_lib assert

  load "$BATS_CWD/logr.sh"
}

@test "should print" {
  run logr info foo
  assert_output " ℹ foo"
}

@test "should print icon only" {
  run logr info
  assert_output " ℹ "
}

@test "should printf" {
  run logr info 'foo %*s' 5 bar
  assert_output " ℹ foo   bar"
}
