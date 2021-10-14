#!/usr/bin/env bats

setup() {
  load 'helpers/common.sh'
  load_lib support
  load_lib assert

  load "$BATS_CWD/logr.sh"
}


@test "should format nothing" {
  run banr
  assert_output "░░░░░░░"
}
@test "should one-component word" {
  run banr foo
  assert_output "░░░░░░░ FOO"
}
@test "should two-component word" {
  run banr fooBar
  assert_output "░░░░░░░ FOO BAR"
}
@test "should two-component word and words" {
  run banr fooBar baz
  assert_output "░░░░░░░ FOO BAR BAZ"
}
@test "should one-component word and words" {
  run banr foo bar baz
  assert_output "░░░░░░░ FOO BAR BAZ"
}
