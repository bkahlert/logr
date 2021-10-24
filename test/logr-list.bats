#!/usr/bin/env bats

setup() {
  load 'helpers/common.sh'
  load_lib support
  load_lib assert

  load "$BATS_CWD/logr.sh"
}

@test "should print" {
  run logr list foo
  assert_output " ▪ foo"
}

@test "should print icon only" {
  run logr list
  [ ! "${output-}" ]
}

@test "should print list" {
  run logr list foo bar
  assert_output ' ▪ foo'' ''
 ▪ bar'
}

@test "should print list --inline" {
  run logr --inline list foo bar
  assert_output '▪ foo  ▪ bar'
}

@test "should print list -i" {
  run logr -i list foo bar
  assert_output '▪ foo  ▪ bar'
}
