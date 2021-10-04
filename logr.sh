#!/usr/bin/env bash
#
# logr — yet another bash logger
# https://github.com/bkahlert/logr
#
# MIT License
#
# Copyright (c) 2021 Dr. Björn Kahlert
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

set -euo pipefail

# Indicates an occurred problem and exits.
# Globals:
#   FUNCNAME
# Arguments:
#   n - optional name of the failed unit (determined using FUNCNAME by default)
#   u - optional usage information; output is automatically preceded with the name
#   - - optional; used declare remaining arguments as positional arguments
#   * - arguments the original unit was called with
failr() {
  local -a stacktrace=() j
  for i in "${!BASH_LINENO[@]}"; do
    [ "${BASH_LINENO[i]}" = 0 ] || stacktrace+=("${FUNCNAME[i+1]:-?}(${BASH_SOURCE[i+1]:-?}:${BASH_LINENO[i]:-?})")
  done

  local code=$? failr_usage="[-n|--name NAME] [-u|--usage USAGE] [--] [ARGS...]" name=${FUNCNAME[1]:-?} message=() usage print_call=false
  while (($#)); do
    case $1 in
      -n | --name)
        [ "${2-}" ] || failr "value of name missing" --usage "$failr_usage" -- "$@"
        name=$2
        shift 2
        ;;
      -u | --usage)
        [ "${2-}" ] || failr "value of usage missing" --usage "$failr_usage" -- "$@"
        usage=$2
        shift 2
        ;;
      -c | --code)
        [ "${2-}" ] || failr "value of code missing" --usage "$failr_usage" -- "$@"
        code=$2
        shift 2
        ;;
      --)
        shift
        print_call=true
        break
        ;;
      *)
        message+=("$1")
        shift
        ;;
    esac
  done

  local invocation="$name"
  if [[ "$print_call" == true ]]; then
    if [[ $# == 0 ]]; then
      invocation="${name} ${tty_italic}[no arguments]${tty_italic_end}"
    else
      invocation="${name} ${tty_underline}$*${tty_underline_end}"
    fi
  fi

  local msg
  printf -v msg '\n%s ✘ %s failed%s%s\n' "$tty_red" "$invocation" \
    "${message+: "$tty_bold${message[*]}$tty_stout_end"}" "$tty_reset"

  [ "${#stacktrace[@]}" -eq 0 ] || msg+="$(printf '     at %s\n' "${stacktrace[@]}")$LF"
  [ ! "${usage-}" ] || msg+="   Usage: $name ${usage//$LF/$LF   }$LF"

  printf '%s\n' "$msg" >&2

  if [[ "${code:-0}" == "0" ]]; then
    exit 1
  else
    exit "$code"
  fi
}

# Invokes a utility function.
# Arguments:
#   v - same behavior as `printf -v`
#   n - if set, appends a newline
#   * - args passed to the utility function.
util() {
  local args=() util_var newline usage="[-v VAR] [-n|--newline] UTIL [ARGS...]"
  while (($#)); do
    case $1 in
      -v)
        [ "${2-}" ] || failr "value of var missing" --usage "$usage" -- "$@"
        util_var=$2
        shift 2
        ;;
      -n | --newline)
        newline=$2
        shift 1
        ;;
      *)
        args+=("$1")
        shift
        ;;
    esac
  done
  set -- "${args[@]}"
  [[ $# == "0" ]] && failr "util missing" --usage "$usage" -- "$@"

  # utilities
  local util_text
  case $1 in
  inline)
    usage="${usage%UTIL*}$1 TEXT"
    shift

    [[ $# -ge 1 ]] || failr "text missing" --usage "$usage" -- "$@"

    local text="$*"
    text=${text#$LF}
    text=${text%$LF}
    text=${text//$LF*$LF/; ...; }
    text=${text//$LF/; }

    printf -v util_text "%s" "$text"
    ;;

  center)
    args=() usage="${usage%UTIL*}$1 [-w|--width WIDTH] TEXT"
    shift
    local util_center_width
    while (($#)); do
      case $1 in
        -w | --width)
          [ "${2-}" ] || failr "value of width missing" --usage "$usage" -- "$@"
          util_center_width=$2
          shift 2
          ;;
        *)
          args+=("$1")
          shift
          ;;
      esac
    done

    set -- "${args[@]}"
    [[ $# -eq 1 ]] || failr "text missing" --usage "$usage" -- "$@"

    local -i available_width=${#MARGIN} text_width="${util_center_width:-${#1}}"
    local -i lpad=$(( (available_width - text_width) / 2 ))
    [[ "$lpad" -gt 0 ]] || lpad=0
    local -i rpad=$(( available_width - text_width - lpad ))
    [[ "$rpad" -gt 0 ]] || rpad=0

    printf -v util_text "%*s%s%*s" "$lpad" '' "$1" "$rpad" ''
    ;;

  cursor)
    usage="${usage%UTIL*}$1 show | hide"
    shift
    [[ $# -eq 1 ]] || failr "command missing" --usage "$usage" -- "$@"
    case $1 in
      show)
        shift
        printf -v util_text '%s' "$tty_show"
        ;;
      hide)
        shift
        printf -v util_text '%s' "$tty_hide"
        ;;
      *)
        failr "unknown command" --usage "$usage" -- "$@"
        ;;
    esac
    ;;

  icon)
    args=() usage="${usage%UTIL*}$1 [-c|--center] ICON"
    shift
    local center
    while (($#)); do
      case $1 in
        -c | --center)
          center=true
          shift 1
          ;;
        *)
          args+=("$1")
          shift
          ;;
      esac
    done
    set -- "${args[@]}"
    [ $# -eq 1 ] || failr "icon missing" --usage "$usage" -- "$@"
    local icon template
    icon=${logr_icons[${1,,}]-'?'}
    template=${logr_templates[${1,,}]-'%s'}
    [ ! ${center-} ] || util center -v icon "$icon"
    printf -v util_text "$template" "$icon"
    ;;

  # prints on the margin without changing the cursor
  print_margin)
    usage="${usage%UTIL*}$1 TEXT"
    shift
    [[ $# -eq 1 ]] || failr "text missing" --usage "$usage" -- "$@"
    printf -v util_text '%s%s%s%s' "$tty_save" "$tty_hpa0" "${1?text missing}" "$tty_load"
    ;;

  # prints the optional icon and text from the start of the line
  print_line)
    args=() usage="${usage%UTIL*}$1 [-i|--icon ICON] [TEXT...]"
    shift
    local print_line_icon="$MARGIN"
    while (($#)); do
      case $1 in
        -i | --icon)
          [ "${2-}" ] || usage
          util icon -v print_line_icon --center "$2"
          shift 2
          ;;
        *)
          args+=("$1")
          shift
          ;;
      esac
    done
    set -- "${args[@]}"
    local inlined && util -v inlined inline "$*"
    printf -v util_text '%s%s%s' "$tty_hpa0" "$print_line_icon" "$inlined"
    ;;

  # prints the optional icon and text from the end of the line
  print_line_end)
    args=() usage="${usage%UTIL*}$1 [-i|--icon ICON] [TEXT...]"
    shift
    local print_line_end_icon="$MARGIN"
    while (($#)); do
      case $1 in
        -i | --icon)
          [ "${2-}" ] || usage
          util icon -v print_line_end_icon --center "$2"
          shift 2
          ;;
        *)
          args+=("$1")
          shift
          ;;
      esac
    done
    set -- "${args[@]}"
    util -v print_line_end_icon print_margin "$print_line_end_icon"
    printf -v util_text '%s%s' "$print_line_end_icon" "${*}"
    ;;

  *)
    failr "unknown command" --usage "$usage" -- "$@"
  esac

  # output
  [ ! "${newline-}" ] || printf -v "util_text" '%s\n' "$util_text"
  if [ "${util_var-}" ]; then
    printf -v "$util_var" '%s' "$util_text"
  else
    printf '%s' "$util_text"
  fi
}

# Invokes a spinner function.
# Arguments:
#   * - args passed to the spinner function.
spinner() {
  local usage="start | is_active | stop"
  [ $# -gt 0 ] || failr "command missing" --usage "$usage" -- "$@"
  case $1 in
  start)
    shift
    [[ $# == 0 ]] || failr "unexpected argument" --usage "$usage" -- "$@"
    spinner stop
    spinner _spin &
    ;;
  is_active)
    shift
    [[ $# == 0 ]] || failr "unexpected argument" --usage "$usage" -- "$@"
    jobs -p 'spinner _spin' >/dev/null 2>/dev/null
    ;;
  stop)
    shift
    [[ $# == 0 ]] || failr "unexpected argument" --usage "$usage" -- "$@"
    if spinner is_active; then
      jobs -p 'spinner _spin' | xargs -r kill
    fi
    ;;
  _spin)
    shift
    [[ $# == 0 ]] || failr "unexpected argument" --usage "$usage" -- "$@"
    local -a frames=()
    read -ra frames <<< "⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏"
    for i in "${!frames[@]}"; do
      util center -v "frames[$i]" "${frames[$i]}"
    done
    while true; do
      for i in "${!frames[@]}"; do
        util print_margin "$tty_bright_yellow${frames[$i]}$tty_load"
        sleep 0.10
      done
    done
    ;;
  *)
    failr "unknown command" --usage "$usage" -- "$@"
  esac
}

# Logs according to the given type.
# Globals:
#   MARGIN
#   LOGR_SPINNER_PID
#   LOGR_VERSION
#   PWD
#   TMPDIR
#   item
#   pid
# Arguments:
#   0 - type
#   * - type arguments
# Returns:
#  task_exit_status ...
#   0 - success
#   1 - error
#   * - signal
logr() {
  local usage="COMMAND"
  case ${1:-'-h'} in
  -h | --help)
   printf '\n   logr v%s\n\n   Usage: logr %s%s' "$LOGR_VERSION" "$usage" '

   Commands:
     new         Log a new item
     item        Log an item
     list        Log a list of items
     link        Log a link
     file        Log a file link

     success     Log a success message
     info        Log an informational message
     warn        Log a warn
     error       Log an error
     fail        Log an error and terminate
'
    ;;
  _init)
    shift
    trap 'logr _abort $?' INT TERM
    trap 'logr _cleanup' EXIT
    util cursor hide
    ;;
  _cleanup)
    shift
    util cursor show
    for pid in $(jobs -p); do
      kill "$pid" &>/dev/null || true
    done
    ;;
  _abort)
    shift
    local code=${1+$((128+$1))}
    logr _cleanup
    failr --code "${code:-1}" "Aborted" || true
    ;;

  new | item | success | info | warn | error | fail)
    util --newline print_line --icon "$1" "${@:2}"
    [[ $1 != "fail" ]] || return 1
    ;;
  list)
    shift
    for item in "$@"; do logr item "$item"; done
    ;;
  link)
    usage="${usage%COMMAND*}$1 URL [TEXT]"
    shift
    [[ $# -ge "1" ]] || failr "url missing" --usage "$usage" -- "$@"
    local link url="$1" text=${2:-$1}
    # shellcheck disable=SC1003
    printf -v link '\e]8;;%s\e\\%s\e]8;;\e\\' "$url" "$text"
    util --newline print_line --icon link "$link"
    ;;
  file)
    usage="${usage%COMMAND*}$1 [-l|--line LINE [-c|--column COLUMN]] PATH [TEXT]"
    shift
    local args=() line column
    while (($#)); do
      case $1 in
        -l | --line)
          [ "${2-}" ] || failr "value of line missing" --usage "$usage" -- "$@"
          line=$2
          shift 2
          ;;
        -c | --column)
          [ "${2-}" ] || failr "value of column missing" --usage "$usage" -- "$@"
          column=$2
          shift 2
          ;;
        *)
          args+=("$1")
          shift
          ;;
      esac
    done
    set -- "${args[@]}"
    [ $# -ge 1 ] || failr "path missing" --usage "$usage" -- "$@"
    local path=$1
    [[ $path =~ ^/ ]] || path="$PWD/$path"
    if [ "${line-}" ]; then
      path+=":$line"
      if [ "${column-}" ]; then
        path+=":$column"
      fi
    fi
    local link url="file://$path" text=${2:-file://$path}
    # shellcheck disable=SC1003
    printf -v link '\e]8;;%s\e\\%s\e]8;;\e\\' "$url" "$text"
    util --newline print_line --icon file "$link"
    ;;
  task)
    usage="${usage%COMMAND*}$1 [MESSAGE] [-w|--warn-only] [-- COMMAND [ARGS...]]"
    shift
    local message=() warn_only
    while (($#)); do
      case $1 in
        -w | --warn-only)
          warn_only=true
          shift 1
          ;;
        --)
          shift
          break
          ;;
        *)
          message=("$1")
          shift
          ;;
      esac
    done
    local -a cmdline=("$@")
    [ "${#message[@]}" -gt 0 ] || message=("${cmdline[@]}")

    if [[ "${#message[@]}" -eq 0 ]] && [[ "${#cmdline[@]}" -eq 0 ]]; then
      failr "message or command missing" --usage "$usage" -- "$@"
    fi

    util print_line --icon task "${message[@]}"

    if [[ "${#cmdline[@]}" -eq 0 ]]; then
      printf '%s\n' ''
      return 0
    fi

    spinner start

    local logfile
    logfile=${TMPDIR:-/tmp}/logr.$$.log
    "${cmdline[@]}" 1>"$logfile" 2>"$logfile" &
    local task_pid=$! task_exit_status=0
    wait "$task_pid" || task_exit_status=$? || true

    spinner stop

    if [[ "$task_exit_status" == 0 ]]; then
      util --newline print_line_end --icon success
      return 0
    fi

    if [ "${warn_only-}" ]; then
      util --newline print_line_end --icon warn
      sed -e 's/^/'"$MARGIN$tty_yellow"'/' \
          -e 's/$/'"$tty_reset"'/' \
        "$logfile" >&2
      return 0
    fi

    util --newline print_line_end --icon error
    sed -e 's/^/'"$MARGIN$tty_red"'/' \
        -e 's/$/'"$tty_reset"'/' \
        "$logfile" >&2
    exit $task_exit_status
    ;;
  *)
    failr "unknown command" --usage "$usage" -- "$@"
    ;;
  esac
}

# Initializes environment
main() {
  TMPDIR=${TMPDIR:-/tmp} TMPDIR=${TMPDIR%/}

  # bashsupport disable=BP5006
  declare -g -r LOGR_VERSION=0.1.0 MARGIN='   ' LF=$'\n'

  # bashsupport disable=BP2001
  # shellcheck disable=SC2034
  declare -g tty_alt='' tty_alt_end='' tty_hpa0='' tty_hide='' tty_show='' tty_save='' tty_load='' \
    tty_dim='' tty_bold='' tty_stout='' tty_stout_end='' tty_underline='' tty_underline_end='' \
    tty_reset='' tty_blink='' tty_italic='' tty_italic_end='' tty_black='' tty_white='' \
    tty_bright_black='' tty_bright_white='' tty_default='' tty_eed='' tty_eel='' tty_ebl='' tty_ewl='' \
    tty_red='' tty_green='' tty_yellow='' tty_blue='' tty_magenta='' tty_cyan='' \
    tty_bright_red='' tty_bright_green='' tty_bright_yellow='' tty_bright_blue='' tty_bright_magenta='' tty_bright_cyan=''

  # escape sequences if terminal is connected
  # shellcheck disable=SC2034
  [ -t 2 ] && [ ! "$TERM" = dumb ] && {
    COLUMNS=$({ tput cols || tput co; } 2>&3) # columns per line
    LINES=$({ tput lines || tput li; } 2>&3)  # lines on screen
    tty_alt=$(tput smcup || tput ti)          # start alt display
    tty_alt_end=$(tput rmcup || tput te)      # end alt display
    tty_hpa0=$(tput hpa 0)                    # set horizontal abs pos 0
    tty_hide=$(tput civis || tput vi)         # hide cursor
    tty_show=$(tput cnorm || tput ve)         # show cursor
    tty_save=$(tput sc)                       # save cursor
    tty_load=$(tput rc)                       # load cursor
    tty_dim=$(tput dim || tput mh)            # start dim
    tty_bold=$(tput bold || tput md)          # start bold
    tty_stout=$(tput smso || tput so)         # start stand-out
    tty_stout_end=$(tput rmso || tput se)     # end stand-out
    tty_underline=$(tput smul || tput us)     # start underline
    tty_underline_end=$(tput rmul || tput ue) # end underline
    tty_reset=$(tput sgr0 || tput me)         # reset cursor
    tty_blink=$(tput blink || tput mb)        # start blinking
    tty_italic=$(tput sitm || tput ZH)        # start italic
    tty_italic_end=$(tput ritm || tput ZR)    # end italic

    # escape sequences for terminals not in mono mode
    [[ $TERM != *-m ]] && {
      tty_red=$(tput setaf 1 || tput AF 1)
      tty_green=$(tput setaf 2 || tput AF 2)
      tty_yellow=$(tput setaf 3 || tput AF 3)
      tty_blue=$(tput setaf 4 || tput AF 4)
      tty_magenta=$(tput setaf 5 || tput AF 5)
      tty_cyan=$(tput setaf 6 || tput AF 6)
      tty_bright_red=$(tput setaf 9 || tput AF 9)
      tty_bright_green=$(tput setaf 10 || tput AF 10)
      tty_bright_yellow=$(tput setaf 11 || tput AF 11)
      tty_bright_blue=$(tput setaf 12 || tput AF 12)
      tty_bright_magenta=$(tput setaf 13 || tput AF 13)
      tty_bright_cyan=$(tput setaf 14 || tput AF 14)
    }
    tty_black=$(tput setaf 0 || tput AF 0)
    tty_white=$(tput setaf 7 || tput AF 7)
    tty_bright_black=$(tput setaf 8 || tput AF 8)
    tty_bright_white=$(tput setaf 15 || tput AF 15)
    tty_default=$(tput op)
    tty_eed=$(tput ed || tput cd)             # erase to end of display
    tty_eel=$(tput el || tput ce)             # erase to end of line
    tty_ebl=$(tput el1 || tput cb)            # erase to beginning of line
    tty_ewl=$tty_eel$tty_ebl                  # erase whole line
  } 3>&2 2>/dev/null || :

  declare -A -g -r logr_icons=(
    ['new']='✱'
    ['item']='▪'
    ['link']='↗'
    ['file']='↗'
    ['task']='☐'
    ['success']='✔'
    ['info']='ℹ'
    ['warn']='⚠'
    ['error']='✘'
    ['fail']='⚡'
 )

   local r=$tty_reset
  declare -A -g -r logr_templates=(
    ['new']="${tty_yellow}%s$r"
    ['link']="${tty_blue}%s$r"
    ['file']="${tty_blue}%s$r"
    ['task']="${tty_blue}%s$r"
    ['success']="${tty_green}%s$r"
    ['info']="${tty_white}%s$r"
    ['warn']="${tty_bright_yellow}%s$r"
    ['error']="${tty_red}%s$r"
    ['fail']="${tty_red}%s$r"
  )

  # Checks if the given shell option is available and activates it. Fails otherwise.
  # Arguments:
  #   1 - shell option name
  require_shopt() {
    test $# -eq 1 || failr --usage "option" -- "$@"
    ! shopt -q "$1" || failr "unsupported shell option" -- "$@"
    shopt -s "$1" || failr "failed to activate shell option" -- "$@"
  }

  require_shopt globstar # ** matches all files and any number of dirs and sub dirs
  require_shopt checkjobs # check for running jobs before exiting
  stty -echoctl 2>/dev/null || true # don't echo control characters in hat notation (e.g. `^C`)

  [ "${BATS_VERSION-}" ] || logr _init
}

main "$@"
