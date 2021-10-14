#!/usr/bin/env bats

setup() {
  load 'helpers/common.sh'
  load_lib support
  load_lib assert

  load "$BATS_CWD/logr.sh"
}

@test "should print icon and format" {
  run util reprint --icon new '%s-%s' foo bar
  assert_output " ✱ foo-bar"
}

@test "should print running icon if not specified" {
  run util reprint 'text'
  assert_output " ⚙ text"
}

@test "should print question mark on unknown icon " {
  run util reprint --icon unknown-icon "text"
  assert_output " ? text"
}
