#!/usr/bin/env bats

setup() {
  load 'helpers/common.sh'
  load_lib support
  load_lib assert

  load "$BATS_CWD/logr.sh"
}

@test "should prefix specified text" {
  run util prefix '%s-%s' foo bar
  assert_output "▔▔▔▔▔▔▔ foo-bar"
}

@test "should prefix no text" {
  run util prefix
  assert_output "▔▔▔▔▔▔▔"
}

@test "should apply config" {
  run util prefix --config 'char=A state=0 : char=Z state=1'
  assert_output "AZ▔▔▔▔▔"
}

@test "should apply short keys" {
  run util prefix --config 'c=A s=0 : c=Z s=1'
  assert_output "AZ▔▔▔▔▔"
}

@test "should apply use shade and bright color by default" {
  run util prefix --config ' : c=Z s=1'
  assert_output "▔Z▔▔▔▔▔"
}

@test "should apply partial props" {
  run util prefix --config 'c=A'
  assert_output "A▔▔▔▔▔▔"
}

@test "should apply multiple characters" {
  run util prefix --config 'c=ABC'
  assert_output "ABC▔▔▔▔▔▔"
}

@test "should delete on empty char" {
  run util prefix --config 'c='
  assert_output "▔▔▔▔▔▔"
}

@test "should support non-BMP chars" {
  run util prefix --config 'c=𖠁'
  assert_output "𖠁▔▔▔▔▔▔"
}

@test "should ignore exceeding arguments" {
  run util prefix --config ':::::::invalid'
  assert_output "▔▔▔▔▔▔▔"
}

@test "should print usage on missing config value" {
  run util prefix --config
  assert_line --partial "failed: value for config missing"
  assert_line --partial "Usage: util [-v VAR] prefix [--config CONFIG] [FORMAT [ARGS...]]"
}

@test "should print usage on invalid config" {
  run util prefix --config 'invalid'
  assert_line --partial "failed: unknown prop 'invalid'; expected colon (:) separated list of space ( ) separated key=value pairs"
}
