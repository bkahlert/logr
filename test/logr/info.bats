#!/usr/bin/env bats

setup() {
  load "$BATS_CWD/logr.sh"
}

@test "should print" {
  run logr info foo
  assert_output $' \xE2\x84\xB9\xEF\xB8\x8E foo'
}

@test "should print icon only" {
  run logr info
  assert_output $' \xE2\x84\xB9\xEF\xB8\x8E '
}

@test "should print under C locale" {
  run env LC_ALL=C bash -c 'source "$1"; logr info foo' _ "$BATS_CWD/logr.sh"
  assert_output $' \xE2\x84\xB9\xEF\xB8\x8E foo'
}

@test "should printf" {
  run logr info 'foo %*s' 5 bar
  assert_output $' \xE2\x84\xB9\xEF\xB8\x8E foo   bar'
}

@test "should printf --inline" {
  run logr --inline info 'foo %*s' 5 bar
  assert_output $'\xE2\x84\xB9\xEF\xB8\x8E foo   bar'
}

@test "should printf -i" {
  run logr -i info 'foo %*s' 5 bar
  assert_output $'\xE2\x84\xB9\xEF\xB8\x8E foo   bar'
}
