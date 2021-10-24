#!/usr/bin/env bats

setup() {
  load 'helpers/common.sh'
  load_lib support
  load_lib assert

  load "$BATS_CWD/logr.sh"
}

@test "should print" {
  run logr fail foo
  assert_output " ϟ foo"
}

@test "should print icon only" {
  run logr fail
  assert_output " ϟ "
}

@test "should printf" {
  run logr fail 'foo %*s' 5 bar
  assert_output " ϟ foo   bar"
}

@test "should printf --inline" {
  run logr --inline fail 'foo %*s' 5 bar
  assert_output "ϟ foo   bar"
}

@test "should printf -i" {
  run logr -i fail 'foo %*s' 5 bar
  assert_output "ϟ foo   bar"
}

# shellcheck disable=SC2154
@test "should exit with code 1" {
  run logr fail foo
  assert_equal "$status" "1"
}
