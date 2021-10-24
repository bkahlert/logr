#!/usr/bin/env bats

setup() {
  load 'helpers/common.sh'
  load_lib support
  load_lib assert

  load "$BATS_CWD/logr.sh"

  MARGIN='   '
  declare -g usage="
$MARGIN
   ▔▔▔▔▔▔▔ LOGR SNAPSHOT

   Usage: logr [-i | --inline] COMMAND [ARGS...]

   Commands:
     created     Log a created item
     added       Log an added item
     item        Log an item
     list        Log a list of items
     link        Log a link
     file        Log a file link

     success     Log a success message
     info        Log an information
     warning     Log a warning
     error       Log an error
     failure     Log an error and terminate"
}

@test "should run specified command" {
  run logr info foo
  assert_output " ℹ foo"
}

@test "should fail on invalid arguments" {
  run logr --illegal
  assert_failure
  assert_line --partial "failed: unknown command"
  assert_line --partial "Usage: logr [-i | --inline] COMMAND [ARGS...]"
}


@test "should warning if executed" {
  run bash "$BATS_CWD/logr.sh"
  assert_line --partial "✘ To use logr you need to source it at the top of your script."
}

@test "should print usage information if executed" {
  run bash "$BATS_CWD/logr.sh"
  assert_failure 2
  assert_line --partial 'source logr.sh'
  assert_line --partial 'source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)/logr.sh"'
  assert_line --partial 'source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)/RELATIVE_PATH/logr.sh"'
  assert_line --partial 'source <(curl -LfsS https://git.io/logr.sh)'
}

@test "should print help if executed with -h flag" {
  run bash "$BATS_CWD/logr.sh" -h
  assert_output "$usage"
  assert_success
}

@test "should print help if executed with --help flag" {
  run bash "$BATS_CWD/logr.sh" --help
  assert_output "$usage"
  assert_success
}
