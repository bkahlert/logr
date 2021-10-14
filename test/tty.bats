#!/usr/bin/env bats

setup() {
  load 'helpers/common.sh'
  load_lib support
  load_lib assert

  load "$BATS_CWD/logr.sh"
}

@test "should print usage" {
  run tty
  assert_line --partial "failed: function missing"
  assert_line --partial "Usage: tty [-v VAR] FUNCTION [ARGS...]"
}
