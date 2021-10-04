#!/usr/bin/env bats

setup() {
  load 'helpers/common.sh'
  load_lib support
  load_lib assert

  load "${BATS_CWD}/logr.sh"
}

@test "should invoke tput command" {
  run tput setaf 1
  assert_output --partial ''
}

@test "should not invoke tput on missing TERM" {
  output="$(unset TERM; tput setaf 1)"
  [[ -z "${output:-}" ]]
}

@test "should apply TERM_OVERRIDE" {
  TERM_OVERRIDE='' run tput setaf 1
  assert_output ''
}
