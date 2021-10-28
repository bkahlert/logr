#!/usr/bin/env bats

setup() {
  load helpers/common.sh
  load_lib support
  load_lib assert
}

# shellcheck disable=SC2059
logr_script() {
  local script && script="$(mktemp "${TMPDIR%/}/script.bash-XXXXXX")"
  cat <<SCRIPT >"$script"
#!/usr/bin/env bash
source logr.sh
$*
SCRIPT
  chmod +x "$script"
  echo "$script"
}

# Invokes an expect script that used the first argument
# to answer the prompt created by running the remaining arguments.
run_prompt() {
  local input=${1?input missing} script quoted
  shift
  quoted=$(printf "'%s' " "$@")
  script=$(logr_script "$quoted")
  local e='echo'
  expect <<EXPECT
set timeout 2
log_user 1
spawn -no$e "$script"
expect "*\[Y/n\]*"
send "$input"
expect {
 "yes"  { exit 0 }
 "no" { exit 10 }
 eof
}
foreach { pid spawn_id os_error_flag value } [wait] break

if {"${os_error_flag-}" == 0} {
  puts "exit status: ${value-}"
  exit "${value-}"
} else {
  puts "errno: ${value-}"
  exit "${value-}"
}
if [ "$input" = "y" ]; then
  expect "(\r\n)+"
else
  eof
fi
EXPECT
}

@test "should prompt default question" {

  run_prompt ' ' prompt4 Y/n

  assert_line --partial "Do you want to continue?"
}

@test "should prompt specified question" {

  run_prompt ' ' prompt4 Y/n "Ok?"

  assert_line --partial "Ok?"
}

@test "should prompt replace - with default question" {

  run_prompt ' ' prompt4 Y/n '%s\n' "This is a message." -

  assert_line --partial "This is a message."
  assert_line --partial "Do you want to continue?"
}

@test "should confirm on y" {

  run_prompt y prompt4 Y/n

  assert_line --partial "✔"
  assert_success
}

@test "should confirm on SPACE" {

  run_prompt '\x20' prompt4 Y/n

  assert_line --partial "✔"
  assert_success
}

@test "should abort on n" {

  run_prompt n prompt4 Y/n

  assert_line --partial "✘"
  assert_failure 10
}

@test "should abort on ESC" {

  run_prompt '\033' prompt4 Y/n

  assert_line --partial "✘"
  assert_failure 10
}

@test "should abort on ^C" {

  run_prompt '\003' prompt4 Y/n

  assert_failure
  assert_failure 10
}
