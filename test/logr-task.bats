#!/usr/bin/env bats

setup() {
  load 'helpers/common.sh'
  load_lib support
  load_lib assert
  load_lib file

  export TERM_OVERRIDE=''
  load "${BATS_CWD}/logr.sh"
}

teardown() {
  unset TERM_OVERRIDE
}

@test "should print usage" {
  run logr task
  assert_line --partial "failed: message or command missing"
  assert_line --partial "Usage: logr task [MESSAGE] [-w|--warn-only] [-- COMMAND [ARGS...]]"
}

@test "should print message" {
  run logr task "message"
  assert_output " ☐ message"
}

@test "should inline multi-line message" {
  run logr task 'message
...
'
  assert_output " ☐ message; ..."
}

@test "should execute specified task" {
  # shellcheck disable=SC2030
  local testfile=$BATS_TEST_TMPDIR/testfile
  run  logr task -- bash -c 'printenv > '"$testfile"
  assert_file_not_empty "$testfile"
}

@test "should not fail on error" {
  run logr logr task -- exit 2
  assert_failure
}

@test "TODO should print error log on error" {
  run logr task -- bash -c '
echo foo && sleep .1
echo bar >&2 && sleep .1
echo baz >&2 && sleep .1
exit 2
'
  refute_line --partial 'foo'
  assert_line --partial 'bar'
  assert_line --partial 'baz'
}

@test "should not fail if warn-only specified" {
  run logr task --warn-only -- exit 2
  assert_success
}
