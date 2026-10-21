#!/usr/bin/env bats

setup() {
  load "$BATS_CWD/logr.sh"
}

@test "should print usage" {
  run util icon
  assert_line --partial "icon missing"
  assert_line --partial "Usage: util [-v VAR] icon [-c|--center] ICON"
}

@test "should print icon" {
  run util icon created
  assert_output "✱"
}

@test "should print iCoN" {
  run util icon CreateD
  assert_output "✱"
}

@test "should print info icon as a single cell" {
  run util icon info
  assert_output "ⓘ"
}

@test "should center info icon" {
  run util icon --center info
  assert_output " ⓘ "
}

@test "should print question mark on unknown icon" {
  run util icon "unknown-icon"
  assert_output "?"
}

@test "should print icon centered if specified" {
  run util icon -c created
  assert_output " ✱ "

  run util icon --center created
  assert_output " ✱ "
}
