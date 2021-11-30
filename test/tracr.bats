#!/usr/bin/env bats

setup() {
  load "$BATS_CWD/logr.sh"
}

@test "should print trace information for 0 arguments" {
  run tracr
  assert_output --partial " 0                                "
}
@test "should print trace information for 1 argument" {
  run tracr foo
  assert_output --partial " 1 foo                            "
}
@test "should print trace information for 2 arguments" {
  run tracr foo bar
  assert_output --partial " 2 foo bar                        "
}

@test "should print to STDERR" {
  run --separate-stderr tracr "foo\n"$'\n'" bar"
  assert_output ''
  # shellcheck disable=SC2154
  assert [ "${#stderr}" -gt 50 ]
}

@test "should shell quote" {
  run tracr "foo\n"$'\n'" bar"
  assert_output --partial " 1 $'foo\\\\n\\n bar'             "
}

@test "should print location URL" {
  run tracr "foo\n"$'\n'" bar"
  assert_output --regexp " ↗ file:///[^#]*#[0-9]+"
}
