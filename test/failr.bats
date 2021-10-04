#!/usr/bin/env bats

setup() {
  load 'helpers/common.sh'
  load_lib support
  load_lib assert

  load "${BATS_CWD}/logr.sh"
}

# shellcheck disable=SC2154
@test "should exit with code 1" {
  run failr
  assert_equal "$status" "1"
}

# shellcheck disable=SC2154
@test "should exit with specified code" {
  run failr -c 2
  assert_equal "$status" "2"

  run failr --code 2
  assert_equal "$status" "2"
}

@test "should print generic message by default" {
  run failr
  assert_output --regexp " ✘ .* failed"
}

@test "should print specified message" {
  run failr "error message"
  assert_output --partial "failed: error message"

  run failr error message
  assert_output --partial "failed: error message"
}

@test "should print specified name" {
  run failr -n name
  assert_output --partial "name failed"

  run failr --name name
  assert_output --partial "name failed"
}

@test "should not print usage by default" {
  run failr -n name
  refute_output --partial "Usage"
}

@test "should print usage if specified" {
  run failr -n foo -u "bar [baz]"
  assert_line "   Usage: foo bar [baz]"

  run failr -n foo --usage "bar [baz]"
  assert_line "   Usage: foo bar [baz]"
}

@test "should print actual call if provided" {
  run failr -n foo -- bar baz
  assert_line " ✘ foo bar baz failed"
}

@test "should print placeholder if zero arguments are provided" {
  run failr -n foo --
  assert_line " ✘ foo [no arguments] failed"
}

@test "should print own usage if called incorrectly" {
  local usage='Usage: failr [-n|--name NAME] [-u|--usage USAGE] [--] [ARGS...]'

  run failr -n
  assert_line --partial "failr -n failed: value of name missing"
  assert_line --partial "$usage"

  run failr -u
  assert_line --partial "failr -u failed: value of usage missing"
  assert_line --partial "$usage"

  run failr -c
  assert_line --partial "failr -c failed: value of code missing"
  assert_line --partial "$usage"
}
