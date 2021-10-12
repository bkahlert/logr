#!/usr/bin/env bats

setup() {
  load 'helpers/common.sh'
  load_lib support
  load_lib assert

  load "$BATS_CWD/logr.sh"
}

@test "should prefix specified text" {
  run util prefix '%s-%s' foo bar
  assert_output "░░░░░░░ foo-bar"
}

@test "should return prefix on missing text" {
  run util prefix
  assert_output "░░░░░░░"
}
