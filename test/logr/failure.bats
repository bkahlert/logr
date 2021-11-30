#!/usr/bin/env bats

setup() {
  load "$BATS_CWD/logr.sh"
}

# shellcheck disable=SC2154
@test "should exit with exit code of last command" {
  bar() {
    return 42
  }
  foo() {
    bar
    logr failure
  }
  run foo
  assert_equal "$status" "42"
}

# shellcheck disable=SC2154
@test "should exit with 1 if last status is 0" {
  bar() {
    return 0
  }
  foo() {
    bar
    logr failure
  }
  run foo
  assert_equal "$status" "1"
}

# shellcheck disable=SC2154
@test "should exit with 0 if specified explicitly" {
  bar() {
    return 0
  }
  foo() {
    bar
    logr failure --code 0
  }
  run foo
  assert_equal "$status" "0"
}

# shellcheck disable=SC2154
@test "should exit" {
  bar() {
    return 42
  }
  foo() {
    bar
    logr failure
    return 49
  }
  run foo
  assert_equal "$status" "42"
}

# shellcheck disable=SC2154
@test "should exit with specified code" {
  run logr failure -c 2
  assert_equal "$status" "2"

  run logr failure --code 2
  assert_equal "$status" "2"
}

@test "should print failure icon" {
  run logr failure
  assert_output --regexp " ϟ .*"
}

@test "should print generic message by default" {
  run logr failure
  assert_output --regexp " ϟ .* failed"
}

@test "should print specified message" {
  run logr failure "error message"
  assert_output --partial "failed: error message"
}

@test "should format specified message" {
  run logr failure "%s--%s" error message
  assert_output --partial "failed: error--message"
}

@test "should print enclosing function by default" {
  foo() { logr failure; }
  run foo
  assert_output --partial "foo failed"
}

@test "should print enclosing function by default despite alias" {
  foo() { logr fail; }
  run foo
  assert_output --partial "foo failed"
}

@test "should print specified name" {
  run logr failure -n name
  assert_output --partial "name failed"

  run logr failure --name name
  assert_output --partial "name failed"
}

@test "should not print usage by default" {
  run logr failure --name name
  refute_output --partial "Usage"
}

@test "should print usage if specified" {
  run logr failure --name foo --usage "bar [baz]"
  assert_line "   Usage: foo bar [baz]"

  run logr failure --name foo --usage "bar [baz]"
  assert_line "   Usage: foo bar [baz]"
}

@test "should print no stacktrace by default" {
  foo() { logr failure; }
  run foo
  refute_line --regexp "at foo\([^:]+:[0-9]+\)"
  refute_line --regexp "at logr\([^:]+:[0-9]+\)"
}

@test "should print stacktrace if specified" {
  foo() { logr failure -x; }
  run foo
  assert_line --regexp "at foo\([^:]+:[0-9]+\)"
  refute_line --regexp "at logr\([^:]+:[0-9]+\)"
}

@test "should print stacktrace if specified despite alias" {
  foo() { logr fail -x; }
  run foo
  assert_line --regexp "at foo\([^:]+:[0-9]+\)"
  refute_line --regexp "at logr\([^:]+:[0-9]+\)"
}

@test "should print actual call if provided" {
  run logr failure --name foo -- bar baz
  assert_line " ϟ foo bar baz failed"
}

@test "should print placeholder if zero arguments are provided" {
  run logr failure --name foo --
  assert_line " ϟ foo [no arguments] failed"
}

@test "should print own usage if called incorrectly" {
  local usage='Usage: logr [-i | --inline] failure [-c|--code CODE] [-n|--name NAME] [-u|--usage USAGE] [FORMAT [ARGS...]] [--] [INVOCATION...]'

  run logr failure --name
  assert_line --partial "logr failure --name: value of name missing"
  assert_line --partial "$usage"

  run logr failure --usage
  assert_line --partial "logr failure --usage: value of usage missing"
  assert_line --partial "$usage"

  run logr failure --code
  assert_line --partial "logr failure --code: value of code missing"
  assert_line --partial "$usage"
}
