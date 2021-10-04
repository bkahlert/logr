#!/usr/bin/env bats

setup() {
  load 'helpers/common.sh'
  load_lib support
  load_lib assert

  load "${BATS_CWD}/logr.sh"
}

@test "should print usage" {
  run util inline
  assert_line --partial "failed: text missing"
  assert_line --partial "Usage: util [-v VAR] [-n|--newline] inline TEXT"
}

@test "should inline 1 line" {
  run util inline 'foo'
  assert_output 'foo'
}

@test "should inline 1 line + trailing line" {
  run util inline 'foo
'
  assert_output 'foo'
}

@test "should inline 1 line + trailing line + leading line" {
  run util inline '
foo
'
  assert_output 'foo'
}

@test "should inline 2 lines" {
  run util inline 'foo
bar'
  assert_output 'foo; bar'
}

@test "should inline 2 lines + trailing line" {
  run util inline 'foo
bar
'
  assert_output 'foo; bar'
}

@test "should inline 2 lines + trailing line + leading line" {
  run util inline '
foo
bar
'
  assert_output 'foo; bar'
}

@test "should inline 3 lines" {
  run util inline 'foo
bar
baz'
  assert_output 'foo; ...; baz'
}

@test "should inline 3 lines + trailing line" {
  run util inline 'foo
bar
baz
'
  assert_output 'foo; ...; baz'
}


@test "should inline 3 lines + trailing line + leading line" {
  run util inline '
foo
bar
baz
'
  assert_output 'foo; ...; baz'
}
