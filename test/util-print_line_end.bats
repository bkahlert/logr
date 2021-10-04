#!/usr/bin/env bats

setup() {
  load 'helpers/common.sh'
  load_lib support
  load_lib assert

  export TERM_OVERRIDE=''
  load "${BATS_CWD}/logr.sh"
}

teardown() {
  unset TERM_OVERRIDE
}

@test "should print icon and text" {
  run util print_line_end -i new 'text'
  assert_output " ✱ text"

  run util print_line_end --icon new 'text'
  assert_output " ✱ text"
}

@test "should print leave icon empty if not specified" {
  run util print_line_end 'text'
  assert_output "   text"
}

@test "should print icon only" {
  run util print_line_end -i new
  assert_output " ✱ "

  run util print_line_end --icon new
  assert_output " ✱ "
}

@test "should print question mark on unknown icon " {
  run util print_line_end -i unknown-icon "text"
  assert_output " ? text"

  run util print_line_end --icon unknown-icon "text"
  assert_output " ? text"
}
