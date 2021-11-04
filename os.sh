#!/usr/bin/env bash

set -uo pipefail

# Runs the specified command line with admin rights.
# Arguments:
#   * - command line
as_admin() {
  [ $# -gt 0 ] || logr error "COMMAND missing" --usage "COMMAND [ARGS...]" -- "$@"
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

  [ $# -gt 0 ] || logr error "app missing" --usage "[--admin] [--] APP [ARGS...]" -- "$@"

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



# Prints the specified error message and exits with an optional exit code (default: 1).
# Arguments:
#   -c | --code - optional exit code (default: 1)
#   --          - indicates that all following arguments are non-options
#   [TEXT...]   - optional error message (default: error in line ${BASH_LINENO[0]})
die() {
  local pattern=' ✘ %s\n'
  [ ! -t 2 ] || pattern="$(tput setaf 1)${pattern}$(tput sgr0)"
  # shellcheck disable=SC2059
  printf "$pattern" "${*:-error in line ${BASH_LINENO[0]}}" >&2
  exit 1
}

# Kills the process listening on the specified port.
kill_listening_process() {
  local port=${1?port missing} pid
  pid=$(lsof -i ":$port" -P -n | tail -n 1 | awk '{print $2}')
  [ ! "${pid}" ] || kill "$pid" || kill "$pid" -9 || die "failed to kill process $pid"
}
