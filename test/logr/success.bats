#!/usr/bin/env bats

setup() {
  load "$BATS_CWD/logr.sh"
}

# shellcheck disable=SC2154
@test "should return exit code of last command" {
  bar() {
    return 42
  }
  foo() {
    bar
    logr success
  }
  run foo
  assert_equal "$status" "42"
}

# shellcheck disable=SC2154
@test "should return 0 if last status is 0" {
  bar() {
    return 0
  }
  foo() {
    bar
    logr success
  }
  run foo
  assert_equal "$status" "0"
}

# shellcheck disable=SC2154
@test "should not exit" {
  bar() {
    return 42
  }
  foo() {
    bar
    logr success
    return 49
  }
  run foo
  assert_equal "$status" "49"
}

# shellcheck disable=SC2154
@test "should return specified code" {
  run logr success -c 2
  assert_equal "$status" "2"

  run logr success --code 2
  assert_equal "$status" "2"
}

@test "should print success icon" {
  run logr success
  assert_output --regexp " ✔ .*"
}

@test "should print no generic message by default" {
  run logr success
  refute_output --regexp " ✔ .* failed"
}

@test "should print specified message" {
  run logr success "error message"
  assert_output --partial ": error message"
}

@test "should format specified message" {
  run logr success "%s--%s" error message
  assert_output --partial ": error--message"
}

@test "should print enclosing function by default" {
  foo() { logr success; }
  run foo
  assert_output --partial "foo"
}

@test "should print enclosing function by default despite alias" {
  foo() { logr succeed; }
  run foo
  assert_output --partial "foo"
}

@test "should print specified name" {
  run logr success -n name
  assert_output --partial "name"

  run logr success --name name
  assert_output --partial "name"
}

@test "should not print usage by default" {
  run logr success --name name
  refute_output --partial "Usage"
}

@test "should print usage if specified" {
  run logr success --name foo --usage "bar [baz]"
  assert_line "   Usage: foo bar [baz]"

  run logr success --name foo --usage "bar [baz]"
  assert_line "   Usage: foo bar [baz]"
}

@test "should print no stacktrace by default" {
  foo() { logr success; }
  run foo
  refute_line --regexp "at foo\([^:]+:[0-9]+\)"
  refute_line --regexp "at logr\([^:]+:[0-9]+\)"
}

@test "should print stacktrace if specified" {
  foo() { logr success -x; }
  run foo
  assert_line --regexp "at foo\([^:]+:[0-9]+\)"
  refute_line --regexp "at logr\([^:]+:[0-9]+\)"
}

@test "should print stacktrace if specified despite alias" {
  foo() { logr warn -x; }
  run foo
  assert_line --regexp "at foo\([^:]+:[0-9]+\)"
  refute_line --regexp "at logr\([^:]+:[0-9]+\)"
}

@test "should print actual call if provided" {
  run logr success --name foo -- bar baz
  assert_line " ✔ foo bar baz"
}

@test "should print placeholder if zero arguments are provided" {
  run logr success --name foo --
  assert_line " ✔ foo [no arguments]"
}

@test "should print own usage if called incorrectly" {
  local usage='Usage: logr [-i | --inline] success [-c|--code CODE] [-n|--name NAME] [-u|--usage USAGE] [FORMAT [ARGS...]] [--] [INVOCATION...]'

  run logr success --name
  assert_line --partial "logr success --name: value of name missing"
  assert_line --partial "$usage"

  run logr success --usage
  assert_line --partial "logr success --usage: value of usage missing"
  assert_line --partial "$usage"

  run logr success --code
  assert_line --partial "logr success --code: value of code missing"
  assert_line --partial "$usage"
}
