#!/usr/bin/env bats

@test "recordings should load the working copy before PATH" {
  cd "$BATS_CWD"
  local recording
  for recording in "$BATS_CWD"/rec/*.rec "$BATS_CWD"/rec/utilities/*.rec; do
    run bash -c '
      rec() { util icon info; exit; }
      source "$1"
    ' -- "$recording"
    assert_success
    assert_line $'\xE2\x84\xB9'
  done
}

@test "prompt recording subprocess should load the working copy before PATH" {
  cd "$BATS_CWD"
  run bash -c '
    rec() { :; }
    source "$1"
    script=$(logr_script "logr info foo")
    bash "$script"
  ' -- "$BATS_CWD/rec/prompt4.rec"
  assert_success
  assert_output $' \xE2\x84\xB9 foo'
}

@test "logr recording should continue after failed recursion examples" {
  cd "$BATS_CWD"
  run bash -c '
    sleep() { :; }
    export -f sleep
    rec() {
      [ "${1-}" != -1 ] || shift
      "$@"
    }
    source "$1" || exit "$?"
  ' -- "$BATS_CWD/rec/logr.rec"
  assert_success
  assert_line --partial "✘ foo 3 2"
  assert_line --partial "foo args: 2 2"
  assert_line --partial "✔ bar 3 -"
  assert_line --partial "bar args: 3 2"
  assert_line --partial "✘ bar 3 2"
  assert_line --partial "✔ running supercalifragilisticexpialidocious without breaking output"
}

setup() {
  printf '%s\n' 'exit 78' >"$BATS_TEST_TMPDIR/logr.sh"
  export PATH="$BATS_TEST_TMPDIR:$PATH"
}
