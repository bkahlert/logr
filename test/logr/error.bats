#!/usr/bin/env bats

setup() {
  load "$BATS_CWD/logr.sh"
}

# shellcheck disable=SC2154
@test "should exit with non-zero exit code of last command" {
  bar() {
    return 42
  }
  foo() {
    bar
    logr error
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
    logr error
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
    logr error --code 0
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
    logr error
    return 49
  }
  run foo
  assert_equal "$status" "42"
}

# shellcheck disable=SC2154
@test "should exit with specified code" {
  run logr error -c 2
  assert_equal "$status" "2"

  run logr error --code 2
  assert_equal "$status" "2"
}

@test "should print error icon" {
  run logr error
  assert_output --regexp " ✘ .*"
}

@test "should print no generic message by default" {
  run logr error
  refute_output --regexp " ✘ .* failed"
}

@test "should print specified message" {
  run logr error "error message"
  assert_output --partial ": error message"
}

@test "should format specified message" {
  run logr error "%s--%s" error message
  assert_output --partial ": error--message"
}

@test "should print enclosing function by default" {
  foo() { logr error; }
  run foo
  assert_output --partial "foo"
}

@test "should print enclosing function by default despite alias" {
  foo() { logr err; }
  run foo
  assert_output --partial "foo"
}

@test "should print specified name" {
  run logr error -n name
  assert_output --partial "name"

  run logr error --name name
  assert_output --partial "name"
}

@test "should not print usage by default" {
  run logr error --name name
  refute_output --partial "Usage"
}

@test "should print usage if specified" {
  run logr error --name foo --usage "bar [baz]"
  assert_line "   Usage: foo bar [baz]"

  run logr error --name foo --usage "bar [baz]"
  assert_line "   Usage: foo bar [baz]"
}

@test "should print no stacktrace by default" {
  foo() { logr error; }
  run foo
  refute_line --regexp "at foo\([^:]+:[0-9]+\)"
  refute_line --regexp "at logr\([^:]+:[0-9]+\)"
}

@test "should print stacktrace if specified" {
  foo() { logr error -x; }
  run foo
  assert_line --regexp "at foo\([^:]+:[0-9]+\)"
  refute_line --regexp "at logr\([^:]+:[0-9]+\)"
}

@test "should print stacktrace if specified despite alias" {
  foo() { logr err -x; }
  run foo
  assert_line --regexp "at foo\([^:]+:[0-9]+\)"
  refute_line --regexp "at logr\([^:]+:[0-9]+\)"
}

@test "should print actual call if provided" {
  run logr error --name foo -- bar baz
  assert_line " ✘ foo bar baz"
}

@test "should print placeholder if zero arguments are provided" {
  run logr error --name foo --
  assert_line " ✘ foo [no arguments]"
}

@test "should print own usage if called incorrectly" {
  local usage='Usage: logr [-i | --inline] error [-c|--code CODE] [-n|--name NAME] [-u|--usage USAGE] [FORMAT [ARGS...]] [--] [INVOCATION...]'

  run logr error --name
  assert_line --partial "logr error --name: value of name missing"
  assert_line --partial "$usage"

  run logr error --usage
  assert_line --partial "logr error --usage: value of usage missing"
  assert_line --partial "$usage"

  run logr error --code
  assert_line --partial "logr error --code: value of code missing"
  assert_line --partial "$usage"
}
