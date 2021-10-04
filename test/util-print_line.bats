#!/usr/bin/env bats

setup() {
  load 'helpers/common.sh'
  load_lib support
  load_lib assert

  load "${BATS_CWD}/logr.sh"
}

@test "should print icon and text" {
  run util print_line -i new 'text'
  assert_output " ✱ text"
}

@test "should print leave icon empty if not specified" {
  run util print_line 'text'
  assert_output "   text"
}

@test "should print icon only" {
  run util print_line -i new
  assert_output " ✱ "
}

@test "should print question mark on unknown icon " {
  run util print_line -i unknown-icon "text"
  assert_output " ? text"
}
