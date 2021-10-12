#!/usr/bin/env bats

setup() {
  load 'helpers/common.sh'
  load_lib support
  load_lib assert

  load "$BATS_CWD/logr.sh"
}

@test "should print banner" {
  run banr foo
  assert_output "░░░░░░░ FOO"
}

@test "should print empty banner" {
  run banr
  assert_output "░░░░░░░"
}

@test "should print two words banner" {
  run banr foo bar
  assert_output "░░░░░░░ FOO BAR"
}

@test "should print three words banner" {
  run banr foo bar baz
  assert_output "░░░░░░░ FOO BAR BAZ"
}

@test "should print camelCase banner" {
  run banr fooBar baz
  assert_output "░░░░░░░ FOO BAR BAZ"

  run banr foo barBaz
  assert_output "░░░░░░░ FOO BAR""BAZ"

  run banr fooBarBaz
  assert_output "░░░░░░░ FOO BAR""BAZ"
}
