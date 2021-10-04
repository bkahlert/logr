#!/usr/bin/env bats

setup() {
  load 'helpers/common.sh'
  load_lib support
  load_lib assert

  load "${BATS_CWD}/logr.sh"
}

@test "should print help" {
  local usage='
   logr v0.1.0

   Usage: logr COMMAND

   Commands:
     new         Log a new item
     item        Log an item
     list        Log a list of items
     link        Log a link
     file        Log a file link

     success     Log a success message
     info        Log an informational message
     warn        Log a warn
     error       Log an error
     fail        Log an error and terminate'

  run logr -h
  assert_output "$usage"
  assert_success

  run logr --help
  assert_output "$usage"
  assert_success
}

@test "should fail on invalid arguments" {
  run logr --illegal
  assert_failure
  assert_line --partial "failed: unknown command"
  assert_line --partial "Usage: logr COMMAND"
}
