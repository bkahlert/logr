#!/usr/bin/env bats

setup() {
  load 'helpers/common.sh'
  load_lib support
  load_lib assert

  load "$BATS_CWD/logr.sh"
}

@test "should print" {
  run logr created foo
  assert_output " ✱ foo"
}

@test "should print icon only" {
  run logr created
  assert_output " ✱ "
}

@test "should printf" {
  run logr created 'foo %*s' 5 bar
  assert_output " ✱ foo   bar"
}

@test "should printf --inline" {
  run logr --inline created 'foo %*s' 5 bar
  assert_output "✱ foo   bar"
}

@test "should printf -i" {
  run logr -i created 'foo %*s' 5 bar
  assert_output "✱ foo   bar"
}
