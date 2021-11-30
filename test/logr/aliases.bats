#!/usr/bin/env bats

setup() {
  load "$BATS_CWD/logr.sh"
}

@test "should produce same output" {
  local expected
  # shellcheck disable=SC2154
  for alias in "${!ICON_ALIASES[@]}"; do
    original=${ICON_ALIASES[$alias]}

    [ ! "$original" = nested ] || continue

    run logr "$original" "$original"
    expected=$output
    run logr "$alias" "$original"
    assert_output "$expected"
  done
}

@test "should produce same status" {
  local expected
  # shellcheck disable=SC2154
  for alias in "${!ICON_ALIASES[@]}"; do
    original=${ICON_ALIASES[$alias]}

    [ ! "$original" = nested ] || continue

    run logr "$original" "$original"
    expected=$status
    run logr "$alias" "$original"
    assert_equal "$status" "$expected"
  done
}

@test "should produce same icon" {
  for alias in "${!ICON_ALIASES[@]}"; do
    original=${ICON_ALIASES[$alias]}
    run util icon "$alias"
    assert_output "$(util icon "$original")"
  done
}
