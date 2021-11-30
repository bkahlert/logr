#!/usr/bin/env bats
# shellcheck disable=SC1090

setup() {
  load "$BATS_CWD/logr.sh"
}

@test "should print on empty list" {
  source "$BATS_CWD/logr.sh"
  run esc
  assert_success
  assert [ ! "${output-}" ]
}

@test "should print ignore unknown capabilities" {
  source "$BATS_CWD/logr.sh"
  run esc foo bar
  assert_success
  assert [ ! "${output-}" ]
}

@test "should enable ANSI support by default" {
  run_tty "bash" "$(mkfile +x '#!/usr/bin/env bash' - <<BASH
TERM=xterm source $BATS_CWD/logr.sh
printf '%q\n' "\${esc_red-}"
BASH
)"
  assert_output --partial "$(printf '%q\n' $'\E[31m')"
}

@test "should disable ANSI support on TERM=dumb" {
  run_tty "bash" "$(mkfile +x '#!/usr/bin/env bash' - <<BASH
TERM=dumb source $BATS_CWD/logr.sh
printf '%q\n' "\${esc_red-}"
BASH
)"
  assert_output $'\'\'\r'
}

@test "should disable ANSI support on NO_COLOR" {
  run_tty "bash" "$(mkfile +x '#!/usr/bin/env bash' - <<BASH
TERM=xterm NO_COLOR=1 source $BATS_CWD/logr.sh
printf '%q\n' "\${esc_red-}"
BASH
)"
  assert_output $'\'\'\r'
}

@test "should disable ANSI support on CUSTOM_NO_COLOR" {
  local bash && bash=$(mkfile +x '#!/usr/bin/env bash' - <<BASH
export CUSTOM_NO_COLOR=1
TERM=xterm source $BATS_CWD/logr.sh
printf '%q\n' "\${esc_red-}"
BASH
)
  mv "$bash" "custom"
  run_tty "bash" "custom"
  assert_output $'\'\'\r'
}

@test "should disable ANSI support on missing terminal" {
  run "bash" "$(mkfile +x '#!/usr/bin/env bash' - <<BASH
TERM=dumb source $BATS_CWD/logr.sh
printf '%q\n' "\${esc_red-}"
BASH
)"
  assert_output "''"
}

run_tty() {
  local script command
  printf -v command " %s" "$@"
  opts='-no''echo'
  script=$(
    mkfile +x '#!/usr/bin/expect' - <<EXPECT
set timeout -1
spawn $opts$command
expect "$ "
EXPECT
  )
  run "$script"
}
