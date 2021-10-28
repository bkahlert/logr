#!/usr/bin/env bats

setup() {
  load helpers/common.sh
  load_lib support
  load_lib assert

  load "$BATS_CWD/logr.sh"
}

@test "should print usage" {
  run logr link
  assert_line --partial "failed: url missing"
  assert_line --partial "Usage: logr [-i | --inline] link URL [TEXT]"
}

@test "should print link" {
  run logr link https://foo/bar
  assert_output " ↗ https://foo/bar"
}

@test "should print link with custom text" {
  run logr link https://foo/bar baz
  assert_output " ↗ [https://foo/bar](baz)"
}

@test "should print link --inline" {
  run logr --inline link https://foo/bar baz
  assert_output "↗ [https://foo/bar](baz)"
}

@test "should print link -i" {
  run logr -i link https://foo/bar baz
  assert_output "↗ [https://foo/bar](baz)"
}
