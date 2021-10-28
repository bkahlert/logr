#!/usr/bin/env bats

setup() {
  load helpers/common.sh
  load_lib support
  load_lib assert

  load "$BATS_CWD/logr.sh"
}


@test "should format nothing" {
  run banr
  assert_output $'\n   ▔▔▔▔▔▔▔'
}
@test "should format one-component word" {
  run banr foo
  assert_output $'\n   ▔▔▔▔▔▔▔ FOO'
}
@test "should format two-component word" {
  run banr fooBar
  assert_output $'\n   ▔▔▔▔▔▔▔ FOO BAR'
}
@test "should format two-component word and words" {
  run banr fooBar baz
  assert_output $'\n   ▔▔▔▔▔▔▔ FOO BAR BAZ'
}
@test "should format one-component word and words" {
  run banr foo bar baz
  assert_output $'\n   ▔▔▔▔▔▔▔ FOO BAR BAZ'
}

@test "should apply indent as number" {
  run banr --indent=5 foo
  assert_output $'\n     ▔▔▔▔▔▔▔ FOO'
}
@test "should apply indent as string" {
  run banr --indent=' bar ' foo
  assert_output $'\n bar ▔▔▔▔▔▔▔ FOO'
}

@test "should apply default config" {
  run banr --static foo bar baz
  assert_output $'\n   ▔▔▔▔▔▔▔ FOO BAR BAZ'
}
@test "should apply specified config" {
  run banr --static='c=>:c=<:c=>:c=<:c=>:c=<:c=>' foo bar baz
  assert_output $'\n   ><><><> FOO BAR BAZ'
}

@test "should apply high opacity" {
  run banr --opacity=high
  assert_output $'\n   ███████'
}
@test "should apply medium opacity" {
  run banr --opacity=medium
  assert_output $'\n   ▒▒▒▒▒▒▒'
}
@test "should apply low opacity" {
  run banr --opacity=low
  assert_output $'\n   ░░░░░░░'
}
@test "should apply low opacity if invalid" {
  run banr --opacity=invalid
  assert_output $'\n   ░░░░░░░'
}
