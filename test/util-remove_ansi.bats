#!/usr/bin/env bats

setup() {
  load helpers/common.sh
  load_lib support
  load_lib assert

  load "$BATS_CWD/logr.sh"
}

@test "should print usage" {
  run util remove_ansi
  assert_line --partial "format missing"
  assert_line --partial "Usage: util [-v VAR] remove_ansi FORMAT [ARGS...]"
}

@test "should use working pattern" {
  assert_replacement() {
    run bash -c "echo '${1?input missing}' | sed '$ESC_PATTERN'"
    assert_success
    assert_output "${2?expectation missing}"
  }

  # Fe escape sequences
  assert_replacement 'B fooBbar' ' foobar'
  assert_replacement 'b foobbar' ' foobar'

  # 2-byte escape sequences
  assert_replacement '(B foo(Bbar' ' foobar'

  # CSI escape sequences
  assert_replacement '[1;2m foo[1;2mbar' ' foobar'
  assert_replacement '[1m foo[1mbar' ' foobar'
  assert_replacement '[m foo[mbar' ' foobar'

  # OSC escape sequences
  assert_replacement ']8;;https://foo.bar\baz]8;;'"\\" 'baz'

  assert_replacement ' [34m↗(B[m ]8;;https://foo.bar\[32mb[43ma(B[mz]8;;'"\\" ' ↗ baz'
}

@test "should cleanse octal escaped escaped" {
  run util remove_ansi "\033[1m bold \033[34m and blue \033[0m"
  assert_output " bold  and blue "
}

@test "should cleanse hexadecimal escaped" {
  run util remove_ansi "\x1B[1m bold \x1B[34m and blue \x1B[0m"
  assert_output " bold  and blue "
}

@test "should cleanse unescaped" {
  run util remove_ansi "[1m bold [34m and blue [0m"
  assert_output " bold  and blue "
}

@test "should format" {
  run util remove_ansi "\033[1m %s \033[34m and %s \033[0m" "bold" "blue"
  assert_output " bold  and blue "
}

@test "should cleanse link" {
  run util remove_ansi "[34m↗(B[m ]8;;https://github.com/bkahlert/logr\\github.com/bkahlert/logr]8;;\\"
  assert_output "↗ github.com/bkahlert/logr"
}
