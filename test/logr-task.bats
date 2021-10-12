#!/usr/bin/env bats

setup() {
  load 'helpers/common.sh'
  load_lib support
  load_lib assert
  load_lib file

  load "$BATS_CWD/logr.sh"
}

@test "should print usage" {
  run logr task
  assert_line --partial "failed: format or command missing"
  assert_line --partial "Usage: logr task [FORMAT [ARGS...]] [-- COMMAND [ARGS...]]"
}

@test "should print" {
  run logr task "foo"
  assert_output " ☐ foo"
}

@test "should printf" {
  run logr task 'foo %*s' 5 bar
  assert_output " ☐ foo   bar"
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

@test "should print error log on error" {
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

@test "should filter escape sequences" {
  run logr task -- bash -c '
echo "foo[1G[37m ℹ (B[mbar" >&2
exit 2
'
  assert_line --partial 'foo ℹ bar'
}
