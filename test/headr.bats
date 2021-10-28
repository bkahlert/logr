#!/usr/bin/env bats

setup() {
  load helpers/common.sh
  load_lib support
  load_lib assert

  load "$BATS_CWD/logr.sh"
}


@test "should format HEADR" {
  run HEADR
  assert_output $'\n   ███████'
}
@test "should format HEADR with one-component word" {
  run HEADR foo
  assert_output $'\n   ███████ FOO'
}
@test "should format HEADR with two-component word" {
  run HEADR fooBar
  assert_output $'\n   ███████ FOO BAR'
}
@test "should format HEADR with two-component word and words" {
  run HEADR fooBar baz
  assert_output $'\n   ███████ FOO BAR BAZ'
}

@test "should format headr" {
  run headr
  assert_output $'\n   ▔▔▔▔▔▔▔'
}
@test "should format headr with one-component word" {
  run headr foo
  assert_output $'\n   ▔▔▔▔▔▔▔ FOO'
}
@test "should format headr with two-component word" {
  run headr fooBar
  assert_output $'\n   ▔▔▔▔▔▔▔ FOO BAR'
}
@test "should format headr with two-component word and words" {
  run headr fooBar baz
  assert_output $'\n   ▔▔▔▔▔▔▔ FOO BAR BAZ'
}
