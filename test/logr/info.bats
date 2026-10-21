#!/usr/bin/env bats

setup() {
  load "$BATS_CWD/logr.sh"
}

@test "should print" {
  run logr info foo
  assert_output " ⓘ foo"
}

@test "should print icon only" {
  run logr info
  assert_output " ⓘ "
}

@test "should print under C locale" {
  run env LC_ALL=C bash -c 'source "$1"; logr info foo' _ "$BATS_CWD/logr.sh"
  assert_output " ⓘ foo"
}

@test "should printf" {
  run logr info 'foo %*s' 5 bar
  assert_output " ⓘ foo   bar"
}

@test "should printf --inline" {
  run logr --inline info 'foo %*s' 5 bar
  assert_output "ⓘ foo   bar"
}

@test "should printf -i" {
  run logr -i info 'foo %*s' 5 bar
  assert_output "ⓘ foo   bar"
}
