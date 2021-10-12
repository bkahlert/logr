#!/usr/bin/env bats

setup() {
  load 'helpers/common.sh'
  load_lib support
  load_lib assert

  load "$BATS_CWD/logr.sh"
}

@test "should format camelCase" {
  run util banner "camelCase"
  assert_output "$(util prefix) CAMEL CASE"
}

@test "should format PascalCase" {
  run util banner "PascalCase"
  assert_output "$(util prefix) PASCAL CASE"
}

@test "should format any CaSe" {
  run util banner "any CaSe"
  assert_output "$(util prefix) ANY CASE"
}

@test "should format camelCamelCase" {
  run util banner "camelCamelCase"
  assert_output "$(util prefix) CAMEL CAMELCASE"
}

@test "should format no text" {
  run util banner
  assert_output "$(util prefix)"
}
