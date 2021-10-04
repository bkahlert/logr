#!/usr/bin/env bats

setup() {
  load 'helpers/common.sh'
  load_lib support
  load_lib assert

  load "${BATS_CWD}/logr.sh"
}

@test "should print usage" {
  run util center
  assert_line --partial "failed: text missing"
  assert_line --partial "Usage: util [-v VAR] [-n|--newline] center [-w|--width WIDTH] TEXT"
}

@test "should center" {
  run util center "X"
  assert_output " X "
}

@test "should center unicode" {
  run util center "✘"
  assert_output " ✘ "
}

@test "should center empty" {
  run util center ""
  assert_output "   "
}

@test "should prefer left if even" {
  run util center "--"
  assert_output "-- "
}

@test "should use specified width" {
  run util center -w 2 "👐"
  assert_output "👐 "

  run util center --width 2 "👐"
  assert_output "👐 "
}

@test "should overprint if to wide" {
  run util center "1234"
  assert_output "1234"
}
