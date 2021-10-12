#!/usr/bin/env bats

setup() {
  load 'helpers/common.sh'
  load_lib support
  load_lib assert
}

# shellcheck disable=SC2059
logr_script() {
  local script && script="$(mktemp "${BATS_TEST_TMPDIR}/script.bash-XXXXXX")"
  cat <<SCRIPT >"$script"
#!/usr/bin/env bash
source $BATS_CWD/logr.sh
$(printf "$@")
SCRIPT
  chmod +x "$script"
  echo "$script"
}

run_prompt() {
  local input=${1?input missing}
  shift
  interact <<EXPECT
set timeout 5
spawn "$(logr_script "
prompt4 $*
echo CONFIRMED
")"
expect "Y/n "
send "$input"
expect "(\r\n)+"
interact
EXPECT
}

@test "should prompt default question" {

  run_prompt ' ' Yn

  assert_line --partial "Do you want to continue?"
}

@test "should prompt specified question" {

  run_prompt ' ' Yn "Ok?"

  assert_line --partial "Ok?"
}

@test "should confirm on y" {

  run_prompt y Yn

  assert_line --partial "✔"
  assert_line --partial "CONFIRMED"
}

@test "should confirm on SPACE" {

  run_prompt '\x20' Yn

  assert_line --partial "✔"
  assert_line --partial "CONFIRMED"
}

@test "should abort on n" {

  run_prompt n Yn

  assert_line --partial "✘"
  refute_line --partial "CONFIRMED"
}

@test "should abort on ESC" {

  run_prompt '\033' Yn

  assert_line --partial "✘"
  refute_line --partial "CONFIRMED"
}

@test "should abort on ^C" {

  run_prompt '\003' Yn

  assert_failure
  assert_line --partial "not open"
}
