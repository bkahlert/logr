#!/usr/bin/env bats

setup() {
  load 'helpers/common.sh'
  load_lib support
  load_lib assert

  TERM_OVERRIDE=''
  load "${BATS_CWD}/logr.sh"
}

teardown() {
  logr _cleanup
  unset TERM_OVERRIDE
}

@test "should print usage" {
  run spinner
  assert_line --partial "failed: command missing"
  assert_line --partial "Usage: spinner start | is_active | stop"
}

@test "should spin" {
  # shellcheck disable=SC2034
  output=$(
    spinner start 3>&-
    sleep 3
    spinner stop
  )
  assert_output --partial "⠋"
  assert_output --partial "⠙"
  assert_output --partial "⠹"
  assert_output --partial "⠸"
  assert_output --partial "⠼"
  assert_output --partial "⠴"
  assert_output --partial "⠦"
}
