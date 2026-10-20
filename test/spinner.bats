#!/usr/bin/env bats

setup() {
  export TERM=xterm
  load "$BATS_CWD/logr.sh"
  export tty_connected=true
}

teardown() {
  # shellcheck disable=SC2034
  export -n tty_connected
  export -n TERM
  logr cleanup
}

@test "should print usage" {
  run spinner
  assert_line --partial "command missing"
  assert_line --partial "Usage: spinner start | stop"
}

@test "should spin" {
  # shellcheck disable=SC2034
  output=$(
    printf '\n'
    spinner start 2>&1
    sleep 3
    spinner stop
  )
  assert_output --partial "⠋"
  assert_output --partial "⠙"
  assert_output --partial "⠹"
  assert_output --partial "⠸"
  assert_output --partial "⠼"
  assert_output --partial "⠴"
  assert_output --partial "⠦"
}

@test "should repeatedly restart and stop only the spinner" {
  run bash -c '
    source "$1"
    set -e
    tty_connected=true
    sleep 30 &
    unrelated=$!
    trap '\''kill "$unrelated" "${first:-$unrelated}" "${second:-$unrelated}" 2>/dev/null || true'\'' EXIT
    assert_stopped() {
      for attempt in {1..50}; do
        if ! kill -0 "$1" 2>/dev/null; then
          wait "$1" 2>/dev/null || true
          return 0
        fi
        sleep .01
      done
      return 1
    }
    for iteration in 1 2 3 4 5; do
      spinner start 2>/dev/null
      first=$!
      spinner start 2>/dev/null
      second=$!
      spinner stop
      assert_stopped "$first"
      assert_stopped "$second"
      kill -0 "$unrelated"
    done
  ' bash "$BATS_CWD/logr.sh"
  assert_success
  assert_output ''
}

@test "should stop without a running spinner and leave other jobs alone" {
  run bash -c '
    source "$1"
    set -e
    tty_connected=true
    sleep 30 &
    unrelated=$!
    trap '\''kill "$unrelated" 2>/dev/null || true'\'' EXIT
    spinner stop
    spinner stop
    kill -0 "$unrelated"
  ' bash "$BATS_CWD/logr.sh"
  assert_success
  assert_output ''
}

@test "should tolerate a spinner exiting between job lookup and kill" {
  run bash -c '
    source "$1"
    set -e
    tty_connected=true
    trap '\''echo "unexpected ERR trap"; exit 42'\'' ERR
    (exit 0) &
    exited=$!
    wait "$exited"
    # Return a stale job PID to reproduce the cleanup race deterministically.
    jobs() { printf "%s\n" "$exited"; }
    spinner stop
    echo continued
  ' bash "$BATS_CWD/logr.sh"
  assert_success
  assert_output 'continued'
}

@test "should preserve errexit and ERR traps after spinner cleanup" {
  run bash -c '
    source "$1"
    set -e
    tty_connected=true
    trap '\''echo "expected ERR trap"; exit 42'\'' ERR
    spinner start 2>/dev/null
    spinner stop
    false
    echo unreachable
  ' bash "$BATS_CWD/logr.sh"
  assert_failure 42
  assert_output 'expected ERR trap'
}

@test "should not start or clean up jobs without a terminal" {
  run bash -c '
    source "$1"
    set -e
    unset tty_connected
    jobs() { exit 42; }
    kill() { exit 42; }
    spinner start
    spinner stop
    test -z "$(builtin jobs -p)"
  ' bash "$BATS_CWD/logr.sh"
  assert_success
  assert_output ''
}
