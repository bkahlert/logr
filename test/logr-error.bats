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

@test "should print" {
  run logr error foo
  assert_output " ✘ foo"
}

@test "should empty" {
  run logr error
  assert_output " ✘ "
}

@test "should print array" {
  run logr error foo bar
  assert_output " ✘ foo bar"
}
