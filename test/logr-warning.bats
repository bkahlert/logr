#!/usr/bin/env bats

setup() {
  load 'helpers/common.sh'
  load_lib support
  load_lib assert

  load "$BATS_CWD/logr.sh"
}

@test "should print" {
  run logr warning foo
  assert_output " ! foo"
}

@test "should print icon only" {
  run logr warning
  assert_output " ! "
}

@test "should print array" {
  run logr warning 'foo %*s' 5 bar
  assert_output " ! foo   bar"
}

@test "should print array --inline" {
  run logr --inline warning 'foo %*s' 5 bar
  assert_output "! foo   bar"
}

@test "should print array -i" {
  run logr -i warning 'foo %*s' 5 bar
  assert_output "! foo   bar"
}
