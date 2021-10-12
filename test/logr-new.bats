#!/usr/bin/env bats

setup() {
  load 'helpers/common.sh'
  load_lib support
  load_lib assert

  load "$BATS_CWD/logr.sh"
}

@test "should print" {
  run logr new foo
  assert_output " ✱ foo"
}

@test "should print icon only" {
  run logr new
  assert_output " ✱ "
}

@test "should printf" {
  run logr new 'foo %*s' 5 bar
  assert_output " ✱ foo   bar"
}
