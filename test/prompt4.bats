#!/usr/bin/env bats

setup() {
  load helpers/common.sh
  load_lib support
  load_lib assert

  cd "$BATS_TEST_TMPDIR" || exit 1
  cat <<SCRIPT > script.sh
#!/usr/bin/env bash
source $BATS_CWD/logr.sh
SCRIPT
  chmod +x script.sh

  MARGIN='   '
  declare -g usage="
$MARGIN
   ▔▔▔▔▔▔▔ PROMPT 4 0.6.1

   Usage: prompt4 TYPE [ARGS...]

   Type:
     Y/n    \"Do you want to continue?\""
}

@test "should prompt specified type" {
  printf '%s\n' "prompt4 Y/n" >> script.sh

  expect <<EXPECT
set timeout 5
spawn ./script.sh
expect "continue?"
send "y"
interact
EXPECT

  assert_success
}

@test "should fail on invalid arguments" {
  printf '%s\n' "prompt4 --illegal" >> script.sh
  run ./script.sh
  assert_failure 64
  assert_line --partial "--illegal: unknown type"
  assert_line --partial "Usage: prompt4 TYPE [ARGS...]"
}


@test "should print help if called with -h flag" {
  printf '%s\n' "prompt4 -h" >> script.sh
  run ./script.sh
  assert_output "$usage"
  assert_success
}

@test "should print help if called with --help flag" {
  printf '%s\n' "prompt4 --help" >> script.sh
  run ./script.sh
  assert_output "$usage"
  assert_success
}
