#!/usr/bin/env bats

setup() {
  load 'helpers/common.sh'
  load_lib support
  load_lib assert

  load "${BATS_CWD}/logr.sh"
}

@test "should print usage" {
  run logr link
  assert_line --partial "failed: url missing"
  assert_line --partial "Usage: logr link URL [TEXT]"
}

@test "should print link" {
  run logr link https://foo/bar
  assert_output --partial ''
  assert_output --partial "https://foo/bar"
}

@test "should print link with custom text" {
  run logr link https://foo/bar baz
  assert_output --partial ''
  assert_output --partial "https://foo/bar"
  assert_output --partial "baz"
}
