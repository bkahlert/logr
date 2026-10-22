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

setup() {
  printf '%s\n' 'exit 78' >"$BATS_TEST_TMPDIR/logr.sh"
  export PATH="$BATS_TEST_TMPDIR:$PATH"
}
