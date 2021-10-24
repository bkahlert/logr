#!/usr/bin/env bats

setup() {
  load 'helpers/common.sh'
  load_lib support
  load_lib assert

  load "$BATS_CWD/logr.sh"
}

@test "should produce same output" {
  for alias in "${!ICON_ALIASES[@]}"; do
    original=${ICON_ALIASES[$alias]}

    [ ! "$original" = nested ] || continue

    run logr "$alias" "$original"
    assert_output "$(logr "$original" "$original" 2>&1 || true)"
  done
}

@test "should produce same icon" {
  for alias in "${!ICON_ALIASES[@]}"; do
    original=${ICON_ALIASES[$alias]}
    run util icon "$alias"
    assert_output "$(util icon "$original")"
  done
}
