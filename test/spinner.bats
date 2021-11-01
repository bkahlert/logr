#!/usr/bin/env bats

setup() {
  load helpers/common.sh
  load_lib support
  load_lib assert

  export TERM=xterm
  load "$BATS_CWD/logr.sh"
  export tty_connected=true
}

teardown() {
  # shellcheck disable=SC2034
  export -n tty_connected
  export -n TERM
  logr _cleanup
}

@test "should print usage" {
  run spinner
  assert_line --partial "command missing"
  assert_line --partial "Usage: spinner start | stop"
}

@test "should spin" {
  # shellcheck disable=SC2034
  output=$(
    printf '\n'
    spinner start 2>&1
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
