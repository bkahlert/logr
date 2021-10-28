#!/usr/bin/env bats

setup() {
  load helpers/common.sh
  load_lib support
  load_lib assert

  load "$BATS_CWD/logr.sh"
}

@test "should print usage" {
  run util remove_ansi
  assert_line --partial "failed: format missing"
  assert_line --partial "Usage: util [-v VAR] remove_ansi FORMAT [ARGS...]"
}

@test "should cleanse SGR (escaped: octal)" {
  run util remove_ansi "\033[1m bold \033[34m and blue \033[0m"
  assert_output " bold  and blue "
}

@test "should cleanse SGR (escaped: hexadecimal)" {
  run util remove_ansi "\x1B[1m bold \x1B[34m and blue \x1B[0m"
  assert_output " bold  and blue "
}

@test "should cleanse SGR (unescaped)" {
  run util remove_ansi "[1m bold [34m and blue [0m"
  assert_output " bold  and blue "
}

@test "should format" {
  run util remove_ansi "\033[1m bold %s" "\033[34m and blue \033[0m"
  assert_output " bold  and blue "
}

@test "should cleanse link" {
  run util remove_ansi "[34m↗(B[m ]8;;https://github.com/bkahlert/logr\\github.com/bkahlert/logr]8;;\\"
  assert_output "↗ github.com/bkahlert/logr"
}
