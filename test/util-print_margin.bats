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

@test "should print usage" {
  run util print_margin
  assert_line --partial "failed: text missing"
  assert_line --partial "Usage: util [-v|--var VAR] [-n|--newline] print_margin TEXT"
}

@test "should print margin" {
  run util print_margin "X"
  assert_output "X"
}
