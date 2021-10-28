#!/usr/bin/env bats

setup() {
  load helpers/common.sh
  load_lib support
  load_lib assert

  load "$BATS_CWD/logr.sh"
}

@test "should print" {
  run logr error foo
  assert_output " ✘ foo"
}

@test "should print icon only" {
  run logr error
  assert_output " ✘ "
}

@test "should printf" {
  run logr error 'foo %*s' 5 bar
  assert_output " ✘ foo   bar"
}

@test "should printf --inline" {
  run logr --inline error 'foo %*s' 5 bar
  assert_output "✘ foo   bar"
}

@test "should printf -i" {
  run logr -i error 'foo %*s' 5 bar
  assert_output "✘ foo   bar"
}

# shellcheck disable=SC2154
@test "should return 1" {
  run logr error foo
  assert_equal "$status" "1"
}
