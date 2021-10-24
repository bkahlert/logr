#!/usr/bin/env bats

setup() {
  load 'helpers/common.sh'
  load_lib support
  load_lib assert

  load "$BATS_CWD/logr.sh"
}

@test "should print" {
  run logr item foo
  assert_output " ▪ foo"
}

@test "should print icon only" {
  run logr item
  assert_output " ▪ "
}

@test "should printf" {
  run logr item 'foo %*s' 5 bar
  assert_output " ▪ foo   bar"
}

@test "should printf --inline" {
  run logr --inline item 'foo %*s' 5 bar
  assert_output "▪ foo   bar"
}

@test "should printf -i" {
  run logr -i item 'foo %*s' 5 bar
  assert_output "▪ foo   bar"
}
