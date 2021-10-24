#!/usr/bin/env bash

set -euo pipefail

# Runs the specified command line with admin rights.
# Arguments:
#   * - command line
as_admin() {
  [ $# -gt 0 ] || failr "COMMAND missing" --usage "COMMAND [ARGS...]" -- "$@"
  osascript -e 'do shell script "'"$*"'" with administrator privileges'
}

# Depending on whether the specified app is running either opens or activates it.
# Arguments:
#   --admin - run the app with administrator privileges
#   --      - denotes the remaining arguments as positional arguments
#   *       - app and optional arguments
open_activate() {
  local admin
  while (($#)); do
    case $1 in
    --admin)
      shift
      admin=true
      ;;
    --)
      shift
      break
      ;;
    *)
      break
      ;;
    esac
  done

  [ $# -gt 0 ] || failr "app missing" --usage "[--admin] [--] APP [ARGS...]" -- "$@"

  local app_path=$1
  local app=${app_path##*/}
  local app_basename=${app%.app}
  if pgrep -q "$app_basename"; then
    osascript -e 'tell application "'"$app_basename"'" to activate'
  else
    if [ "${admin-}" ]; then
      as_admin open "$@"
    else
      open "$@"
    fi
  fi
}


# asks for the admin password upfront
# and keeps sudo alive until the script finishes
sudo_forever() {
  sudo -v
  while true; do
    sudo -n true "$@"
    sleep 60
    kill -0 "$$" || exit
  done 2>/dev/null &
}
