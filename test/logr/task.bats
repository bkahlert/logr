#!/usr/bin/env bats

setup() {
  load "$BATS_CWD/logr.sh"
}

@test "should print usage" {
  run logr task
  assert_line --partial "format or command missing"
  assert_line --partial "Usage: logr [-i | --inline] task [FORMAT [ARGS...]] [-- COMMAND [ARGS...]]"
}

@test "should print" {
  run logr task "foo"
  assert_output " ⚙ foo"
}

@test "should printf" {
  run logr task 'foo %*s' 5 bar
  assert_output " ⚙ foo   bar"
}

@test "should printf to STDOUT" {
  run --separate-stderr logr task 'foo %*s' 5 bar
  assert_output " ⚙ foo   bar"
  # shellcheck disable=SC2154
  assert_equal "$stderr" ''
}

@test "should printf --inline" {
  run logr --inline task 'foo %*s' 5 bar
  assert_output "⚙ foo   bar"
}

@test "should printf -i" {
  run logr -i task 'foo %*s' 5 bar
  assert_output "⚙ foo   bar"
}


@test "should inline multi-line message" {
  run logr task 'message
...
'
  assert_output " ⚙ message; ..."
}

@test "should execute specified task" {
  # shellcheck disable=SC2030
  local testfile=$BATS_TEST_TMPDIR/testfile
  run  logr task -- bash -c 'printenv > '"$testfile"
  assert_file_not_empty "$testfile"
}

@test "should fail on error" {
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

@test "should print errors to STDERR" {
  run --separate-stderr logr task -- bash -c '
echo foo && sleep .1
echo bar >&2 && sleep .1
echo baz >&2 && sleep .1
exit 2
'

  # shellcheck disable=SC2154
  assert_equal "$output" \ \ \ bash\ -c\ \;\ ...\;\ exit\ 2
  # shellcheck disable=SC2154
  assert_equal "$stderr" $'✘ bash -c ; ...; exit 2\n   bar\n   baz'
}

@test "should filter escape sequences" {
  run logr task -- bash -c '
echo "foo[1G[37m ℹ (B[mbar" >&2
exit 2
'
  assert_line --partial 'foo ℹ bar'
}
