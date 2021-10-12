#!/usr/bin/env bats

setup() {
  load 'helpers/common.sh'
  load_lib support
  load_lib assert

  load "$BATS_CWD/logr.sh"

  declare -g usage='
   logr v0.1.0

   Usage: logr COMMAND [ARGS...]

   Commands:
     new         Log a new item
     item        Log an item
     list        Log a list of items
     link        Log a link
     file        Log a file link

     success     Log a success message
     info        Log an information
     warn        Log a warning
     error       Log an error
     fail        Log an error and terminate'
}

@test "should run specified command" {
  run logr info foo
  assert_output " ℹ foo"
}

@test "should fail on invalid arguments" {
  run logr --illegal
  assert_failure
  assert_line --partial "failed: unknown command"
  assert_line --partial "Usage: logr COMMAND [ARGS...]"
}


@test "should fail if executed" {
  run bash "$BATS_CWD/logr.sh"
  assert_failure
  assert_line --partial "✘ To use logr you need to source it at the top of your script."
}

@test "should print help if executed with -h flag" {
  run bash "$BATS_CWD/logr.sh" -h
  assert_output "$usage"
  assert_success
}

@test "should print help if executed with --help flag" {
  run bash "$BATS_CWD/logr.sh" --help
  assert_output "$usage"
  assert_success
}
