#!/usr/bin/env bats

setup() {
  load helpers/common.sh
  load_lib support
  load_lib assert

  load "$BATS_CWD/logr.sh"
}

@test "should print icon and text" {
  run util print --icon created 'text'
  assert_output " ✱ text"
}

@test "should print leave icon empty if not specified" {
  run util print 'text'
  assert_output "   text"
}

@test "should print icon only" {
  run util print --icon created
  assert_output " ✱ "
}

@test "should print question mark on unknown icon " {
  run util print --icon unknown-icon "text"
  assert_output " ? text"
}
