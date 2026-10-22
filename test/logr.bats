#!/usr/bin/env bats

setup() {
  load "$BATS_CWD/logr.sh"

  declare -g usage="
$MARGIN
   ▔▔▔▔▔▔▔ LOGR 0.6.5

   Usage: logr [-i | --inline] COMMAND [ARGS...]

   Commands:
     created     Log a created item
     added       Log an added item
     item        Log an item
     list        Log a list of items
     link        Log a link
     file        Log a file link

     success     Log a success message
     info        Log an information
     warning     Log a warning
     error       Log an error
     failure     Log an error and terminate"
}

@test "should run specified command" {
  run logr info foo
  assert_output $' \xE2\x84\xB9 foo'
}

@test "should fail on invalid arguments" {
  run logr --illegal
  assert_failure 64
  assert_line --partial "--illegal: unknown command"
  assert_line --partial "Usage: logr [-i | --inline] COMMAND [ARGS...]"
}


@test "should succeed silently on execution" {
  run bash "$BATS_CWD/logr.sh"
  assert_success
  assert_output ''
}

@test "should succeed silently on execution with -h" {
  run bash "$BATS_CWD/logr.sh" -h
  assert_success
  assert_output ''
}

@test "should succeed silently on execution with --help" {
  run bash "$BATS_CWD/logr.sh" --help
  assert_success
  assert_output ''
}

@test "should print help on calling logr without arguments" {
  run logr
  assert_success
  assert_output "$usage"
}

@test "should initialize with caller arguments" {
  run bash -c 'source "$1"; logr info foo' -- "$BATS_CWD/logr.sh" -!- --help
  assert_success
  assert_output ' ℹ foo'
}

@test "should do nothing if sourced multiple times" {
  run source "$BATS_CWD/logr.sh"
  run source "$BATS_CWD/logr.sh"
  assert_success
}
