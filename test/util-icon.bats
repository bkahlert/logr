#!/usr/bin/env bats

setup() {
  load 'helpers/common.sh'
  load_lib support
  load_lib assert

  load "${BATS_CWD}/logr.sh"
}

@test "should print usage" {
  run util icon
  assert_line --partial "failed: icon missing"
  assert_line --partial "Usage: util [-v VAR] [-n|--newline] icon [-c|--center] ICON"
}

@test "should print icon" {
  run util icon new
  assert_output "✱"
}

@test "should print iCoN" {
  run util icon NeW
  assert_output "✱"
}

@test "should print question mark on unknown icon" {
  run util icon "unknown-icon"
  assert_output "?"
}

@test "should print icon centered if specified" {
  run util icon -c new
  assert_output " ✱ "

  run util icon --center new
  assert_output " ✱ "
}
