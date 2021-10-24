#!/usr/bin/env bats

setup() {
  load 'helpers/common.sh'
  load_lib support
  load_lib assert

  load "$BATS_CWD/logr.sh"
}

@test "should print" {
  run logr success foo
  assert_output " ✔ foo"
}

@test "should print icon only" {
  run logr success
  assert_output " ✔ "
}

@test "should printf" {
  run logr success 'foo %*s' 5 bar
  assert_output " ✔ foo   bar"
}

@test "should printf --inline" {
  run logr --inline success 'foo %*s' 5 bar
  assert_output "✔ foo   bar"
}

@test "should printf -i" {
  run logr -i success 'foo %*s' 5 bar
  assert_output "✔ foo   bar"
}
