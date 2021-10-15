#!/usr/bin/env bats

setup() {
  load 'helpers/common.sh'
  load_lib support
  load_lib assert

  load "$BATS_CWD/logr.sh"
}


@test "should format nothing" {
  run banr
  assert_output " ░░░░░░░"
}
@test "should format one-component word" {
  run banr foo
  assert_output " ░░░░░░░ FOO"
}
@test "should format two-component word" {
  run banr fooBar
  assert_output " ░░░░░░░ FOO BAR"
}
@test "should format two-component word and words" {
  run banr fooBar baz
  assert_output " ░░░░░░░ FOO BAR BAZ"
}
@test "should format one-component word and words" {
  run banr foo bar baz
  assert_output " ░░░░░░░ FOO BAR BAZ"
}

@test "should apply default config" {
  run banr --static foo bar baz
  assert_output " ░░░░░░░ FOO BAR BAZ"
}
@test "should apply specified config" {
  run banr --static='c=>:c=<:c=>:c=<:c=>:c=<:c=>' foo bar baz
  assert_output " ><><><> FOO BAR BAZ"
}
