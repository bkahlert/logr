#!/usr/bin/env bats

setup() {
  load helpers/common.sh
  load_lib support
  load_lib assert

  load "$BATS_CWD/logr.sh"
}

@test "should print usage" {
  run logr file
  assert_line --partial "path missing"
  assert_line --partial "Usage: logr [-i | --inline] file [-l|--line LINE [-c|--column COLUMN]] PATH [TEXT]"
}

@test "should print file link" {
  run logr file /foo/bar
  assert_output " ↗ file:///foo/bar"
}

@test "should print file link with custom text" {
  run logr file /foo/bar baz
  assert_output " ↗ [file:///foo/bar](baz)"
}

@test "should print file link --inline" {
  run logr --inline file /foo/bar baz
  assert_output "↗ [file:///foo/bar](baz)"
}

@test "should print file link -i" {
  run logr -i file /foo/bar baz
  assert_output "↗ [file:///foo/bar](baz)"
}

@test "should encode line if specified" {
  __CFBundleIdentifier='' run logr file -l 42 /foo/bar
  assert_output --partial "file:///foo/bar#42"

  __CFBundleIdentifier='' run logr file --line 42 /foo/bar
  assert_output --partial "file:///foo/bar#42"
}

@test "should hash encode line if jetBrains is present" {
  __CFBundleIdentifier=com.jetbrains.intellij run logr file -l 42 /foo/bar
  assert_output --partial "file:///foo/bar:42"

  __CFBundleIdentifier=com.jetbrains.intellij run logr file --line 42 /foo/bar
  assert_output --partial "file:///foo/bar:42"
}

@test "should encode column if specified" {
  __CFBundleIdentifier='' run logr file -l 42 -c 24 /foo/bar
  assert_output --partial "file:///foo/bar#42:24"

  __CFBundleIdentifier='' run logr file -l 42 --column 24 /foo/bar
  assert_output --partial "file:///foo/bar#42:24"
}

@test "should not encode column on missing line" {
  run logr file -c 24 /foo/bar
  assert_output --partial "file:///foo/bar"

  run logr file --column 24 /foo/bar
  assert_output --partial "file:///foo/bar"
}

@test "should append absolute path to file" {
  run logr file foo
  assert_output --regexp "file://.*/foo"
}
