#!/usr/bin/env bats

setup() {
  load 'helpers/common.sh'
  load_lib support
  load_lib assert

  load "$BATS_CWD/logr.sh"
}

@test "should print" {
  run logr fail foo
  assert_output " ⚡ foo"
}

@test "should print icon only" {
  run logr fail
  assert_output " ⚡ "
}

@test "should printf" {
  run logr fail 'foo %*s' 5 bar
  assert_output " ⚡ foo   bar"
}

# shellcheck disable=SC2154
@test "should exit with code 1" {
  run logr fail foo
  assert_equal "$status" "1"
}
