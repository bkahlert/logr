#!/usr/bin/env bats

setup() {
  load 'helpers/common.sh'
  load_lib support
  load_lib assert

  load "$BATS_CWD/logr.sh"
}

@test "should format camelCase" {
  run util words "camelCase"
  assert_output "CAMEL CASE"
}
@test "should format PascalCase" {
  run util words "PascalCase"
  assert_output "PASCAL CASE"
}
@test "should format any CaSe" {
  run util words "any CaSe"
  assert_output "ANY CASE"
}
@test "should format camelCamelCase" {
  run util words "camelCamelCase"
  assert_output "CAMEL CAMELCASE"
}

@test "should format first1" {
  run util words "first1"
  assert_output "FIRST 1"
}
@test "should format first 1 third" {
  run util words "first 1 third"
  assert_output "FIRST 1 THIRD"
}
@test "should format first second 23 fourth" {
  run util words "first second 23 THIRD"
  assert_output "FIRST SECOND 23 THIRD"
}

@test "should format nothing" {
  run util words
  assert_output ""
}
@test "should format one-component word" {
  run util words '%s ' foo
  assert_output "FOO"
}
@test "should format two-component word" {
  run util words '%s ' fooBar
  assert_output "FOO BAR"
}
@test "should format two-component word and words" {
  run util words '%s ' fooBar baz
  assert_output "FOO BAR BAZ"
}
@test "should format one-component word and words" {
  run util words '%s ' foo bar baz
  assert_output "FOO BAR BAZ"
}
