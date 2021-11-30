#!/usr/bin/env bats

setup() {
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

@test "should printf --inline" {
  run logr --inline info 'foo %*s' 5 bar
  assert_output "ℹ foo   bar"
}

@test "should printf -i" {
  run logr -i info 'foo %*s' 5 bar
  assert_output "ℹ foo   bar"
}
