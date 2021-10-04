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

# tput wrapper that only invokes tput if TERM is not empty
# Globals:
#   TERM - used by tput to query terminfo
#   TERM_OVERRIDE - if set, overrules TERM
# Arguments:
#   * - tput arguments
tput() {
  local -r term=${TERM_OVERRIDE-${TERM:-}}
  [ -z "$term" ] || TERM=$term command tput "$@"
}

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

  local code=$? failr_usage="[-n|--name NAME] [-u|--usage USAGE] [--] [ARGS...]" name=${FUNCNAME[1]:-UNKNOWN} message=() usage print_call=false
  while (("$#")); do
    case $1 in
      -n | --name)
        [[ -n ${2:-} ]] || failr "value of name missing" --usage "$failr_usage" -- "$@"
        name=$2
        shift 2
        ;;
      -u | --usage)
        [[ -n ${2:-} ]] || failr "value of usage missing" --usage "$failr_usage" -- "$@"
        usage=$2
        shift 2
        ;;
      -c | --code)
        [[ -n ${2:-} ]] || failr "value of code missing" --usage "$failr_usage" -- "$@"
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
      local sitm ritm
      sitm=$(   tput sitm   || tput ZH      ) || true
      ritm=$(   tput ritm   || tput ZR      ) || true
      invocation="$name ${sitm}[no arguments]$ritm"
    else
      invocation="$name $(tput smul)$*$(tput rmul)"
    fi
  fi

  local msg
  printf -v msg '\n%s ✘ %s failed%s%s\n' "$(tput setaf 1)" "$invocation" \
    "${message+: "$(tput bold)${message[*]}$(tput rmso)"}" "$(tput sgr0)"

  [ "${#stacktrace[@]}" -eq 0 ] || msg+="$(printf '     at %s\n' "${stacktrace[@]}")"$'\n'
  [ -z "${usage:-}" ] || msg+="   Usage: $name ${usage//$'\n'/$'\n'   }"$'\n'

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
  local args=() util_var newline usage="[-v|--var VAR] [-n|--newline] UTIL [ARGS...]"
  while (("$#")); do
    case $1 in
      -v | --var)
        [[ -n ${2:-} ]] || failr "value of var missing" --usage "$usage" -- "$@"
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
  [[ "$#" == "0" ]] && failr "util missing" --usage "$usage" -- "$@"

  # utilities
  local util_text
  case $1 in
  inline)
    usage="${usage%UTIL*}$1 TEXT"
    shift

    [[ "$#" -ge 1 ]] || failr "text missing" --usage "$usage" -- "$@"

    local text="$*"
    text=${text#$'\n'}
    text=${text%$'\n'}
    text=${text//$'\n'*$'\n'/; ...; }
    text=${text//$'\n'/; }

    printf -v util_text "%s" "$text"
    ;;

  center)
    args=() usage="${usage%UTIL*}$1 [-w|--width WIDTH] TEXT"
    shift
    local util_center_width
    while (("$#")); do
      case $1 in
        -w | --width)
          [[ -n ${2:-} ]] || failr "value of width missing" --usage "$usage" -- "$@"
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
    [[ "$#" -eq 1 ]] || failr "text missing" --usage "$usage" -- "$@"

    local -i available_width=${#LOGR_MARGIN_LEFT} text_width="${util_center_width:-${#1}}"
    local -i lpad=$(( (available_width - text_width) / 2 ))
    [[ "$lpad" -gt 0 ]] || lpad=0
    local -i rpad=$(( available_width - text_width - lpad ))
    [[ "$rpad" -gt 0 ]] || rpad=0

    printf -v util_text "%*s%s%*s" "$lpad" '' "$1" "$rpad" ''
    ;;

  cursor)
    usage="${usage%UTIL*}$1 show | hide"
    shift
    [[ "$#" -eq 1 ]] || failr "command missing" --usage "$usage" -- "$@"
    case $1 in
      show)
        shift
        printf -v util_text '%s' "$LOGR_CURSOR_SHOW"
        ;;
      hide)
        shift
        printf -v util_text '%s' "$LOGR_CURSOR_HIDE"
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
    while (("$#")); do
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
    [[ "$#" -eq 1 ]] || failr "icon missing" --usage "$usage" -- "$@"
    local icon_ref="LOGR_ICON_${1^^}" format_ref="LOGR_FORMAT_${1^^}"
    local icon format
    if [[ -v "$icon_ref" ]]; then
      icon=${!icon_ref}
    else
      icon='?'
    fi
    if [[ -v "$format_ref" ]]; then
      format=${!format_ref}
    else
      format=""
    fi
    [[ "${center:-}" != true ]] || util center -v icon "$icon"
    printf -v util_text '%s%s%s' "$format" "$icon" "$LOGR_RESET"
    ;;

  # prints on the margin without changing the cursor
  print_margin)
    usage="${usage%UTIL*}$1 TEXT"
    shift
    [[ "$#" -eq 1 ]] || failr "text missing" --usage "$usage" -- "$@"
    printf -v util_text '%s%s%s%s' "$LOGR_CURSOR_SAVE" "$LOGR_CURSOR_COLUMN_MARGIN" "${1?text missing}" "$LOGR_CURSOR_RESTORE"
    ;;

  # prints the optional icon and text from the start of the line
  print_line)
    args=() usage="${usage%UTIL*}$1 [-i|--icon ICON] [TEXT...]"
    shift
    local print_line_icon="$LOGR_MARGIN_LEFT"
    while (("$#")); do
      case $1 in
        -i | --icon)
          [[ -n ${2:-} ]] || usage
          util icon -v print_line_icon -c "$2"
          shift 2
          ;;
        *)
          args+=("$1")
          shift
          ;;
      esac
    done
    set -- "${args[@]}"
    local inlined && util --var inlined inline "$*"
    printf -v util_text '%s%s%s' "$LOGR_CURSOR_COLUMN_MARGIN" "$print_line_icon" "$inlined"
    ;;

  # prints the optional icon and text from the end of the line
  print_line_end)
    args=() usage="${usage%UTIL*}$1 [-i|--icon ICON] [TEXT...]"
    shift
    local print_line_end_icon="$LOGR_MARGIN_LEFT"
    while (("$#")); do
      case $1 in
        -i | --icon)
          [[ -n ${2:-} ]] || usage
          util icon -v print_line_end_icon -c "$2"
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
  [[ -z "${newline:-}" ]] || printf -v "util_text" '%s\n' "$util_text"
  if [[ -n "${util_var:-}" ]]; then
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
  [ "$#" -gt 0 ] || failr "command missing" --usage "$usage" -- "$@"
  case $1 in
  start)
    shift
    [[ "$#" == 0 ]] || failr "unexpected argument" --usage "$usage" -- "$@"
    spinner stop
    spinner _spin &
    ;;
  is_active)
    shift
    [[ "$#" == 0 ]] || failr "unexpected argument" --usage "$usage" -- "$@"
    jobs -p 'spinner _spin' >/dev/null 2>/dev/null
    ;;
  stop)
    shift
    [[ "$#" == 0 ]] || failr "unexpected argument" --usage "$usage" -- "$@"
    if spinner is_active; then
      jobs -p 'spinner _spin' | xargs -r kill
    fi
    ;;
  _spin)
    shift
    [[ "$#" == 0 ]] || failr "unexpected argument" --usage "$usage" -- "$@"
    local -a frames=()
    read -ra frames <<< "⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏"
    for i in "${!frames[@]}"; do
      util center -v "frames[$i]" "${frames[$i]}"
    done
    while true; do
      for i in "${!frames[@]}"; do
        util print_margin "$LOGR_COLOR_FG_BRIGHT_YELLOW${frames[$i]}$LOGR_CURSOR_RESTORE"
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
#   LOGR_MARGIN_LEFT
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
#   $task_exit_status ...
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
    util -n print_line --icon "$1" "${@:2}"
    [[ $1 != "fail" ]] || return 1
    ;;
  list)
    shift
    for item in "$@"; do logr item "$item"; done
    ;;
  link)
    usage="${usage%COMMAND*}$1 URL [TEXT]"
    shift
    [[ "$#" -ge "1" ]] || failr "url missing" --usage "$usage" -- "$@"
    local link url="$1" text=${2:-$1}
    # shellcheck disable=SC1003
    printf -v link '\e]8;;%s\e\\%s\e]8;;\e\\' "$url" "$text"
    util -n print_line --icon link "$link"
    ;;
  file)
    usage="${usage%COMMAND*}$1 [-l|--line LINE [-c|--column COLUMN]] PATH [TEXT]"
    shift
    local args=() line column
    while (("$#")); do
      case $1 in
        -l | --line)
          [[ -n ${2:-} ]] || failr "value of line missing" --usage "$usage" -- "$@"
          line=$2
          shift 2
          ;;
        -c | --column)
          [[ -n ${2:-} ]] || failr "value of column missing" --usage "$usage" -- "$@"
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
    [[ "$#" -ge "1" ]] || failr "path missing" --usage "$usage" -- "$@"
    local path=$1
    [[ $path =~ ^/ ]] || path="$PWD/$path"
    if [[ -n ${line:-} ]]; then
      path+=":$line"
      if [[ -n ${column:-} ]]; then
        path+=":$column"
      fi
    fi
    local link url="file://$path" text=${2:-file://$path}
    # shellcheck disable=SC1003
    printf -v link '\e]8;;%s\e\\%s\e]8;;\e\\' "$url" "$text"
    util -n print_line --icon file "$link"
    ;;
  task)
    usage="${usage%COMMAND*}$1 [MESSAGE] [-w|--warn-only] [-- COMMAND [ARGS...]]"
    shift
    local message=() warn_only
    while (("$#")); do
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

    if [[ -n "${warn_only:-}" ]]; then
      util --newline print_line_end --icon warn
      sed -e 's/^/'"$LOGR_MARGIN_LEFT$LOGR_COLOR_FG_YELLOW"'/' \
          -e 's/$/'"$LOGR_RESET"'/' \
        "$logfile" >&2
      return 0
    fi

    util --newline print_line_end --icon error
    sed -e 's/^/'"$LOGR_MARGIN_LEFT$LOGR_COLOR_FG_RED"'/' \
        -e 's/$/'"$LOGR_RESET"'/' \
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

  # Checks if the given shell option is available and activates it.
  # Otherwise fails.
  # Arguments:
  #   1 - shell option name
  require_shopt() {
    ! shopt -q "${1:?option missing}" || failr "unsupported shell option" -- "$@"
    shopt -s "$1"
  }

  require_shopt globstar # ** matches all files and any number of dirs and sub dirs

  # not active because incompatible with Bats' assert_line (no matches at all)
  # require_shopt nullglob # non-matching globs expand to null (-> no loop iteration)

  require_shopt checkjobs # check for running jobs before exiting

  # don't echo control characters in hat notation (e.g. `^C`)
  stty -echoctl 2>/dev/null || true

  # shellcheck disable=SC2155,SC2034
  # bashsupport disable=BP2001,BP5006
  declare -g \
    LOGR_VERSION=0.1.0 \
    LOGR_MARGIN_LEFT="   "

  # escape sequences if terminal is connected
  if [ -t 2 ] && [ ! $TERM = dumb ]; then
    COLUMNS=$({ tput cols   || tput co;} 2>&3) # Columns in a line
    LINES=$({   tput lines  || tput li;} 2>&3) # Lines on screen
    alt=$(      tput smcup  || tput ti      ) # Start alt display
    ealt=$(     tput rmcup  || tput te      ) # End   alt display
    hide=$(     tput civis  || tput vi      ) # Hide cursor
    show=$(     tput cnorm  || tput ve      ) # Show cursor
    save=$(     tput sc                     ) # Save cursor
    load=$(     tput rc                     ) # Load cursor
    dim=$(      tput dim    || tput mh      ) # Start dim
    bold=$(     tput bold   || tput md      ) # Start bold
    stout=$(    tput smso   || tput so      ) # Start stand-out
    estout=$(   tput rmso   || tput se      ) # End stand-out
    under=$(    tput smul   || tput us      ) # Start underline
    eunder=$(   tput rmul   || tput ue      ) # End   underline
    reset=$(    tput sgr0   || tput me      ) # Reset cursor
    blink=$(    tput blink  || tput mb      ) # Start blinking
    italic=$(   tput sitm   || tput ZH      ) # Start italic
    eitalic=$(  tput ritm   || tput ZR      ) # End   italic

    # escape sequences for terminals not in mono mode
    if [[ $TERM != *-m ]]; then
        red=$(      tput setaf 1|| tput AF 1    )
        green=$(    tput setaf 2|| tput AF 2    )
        yellow=$(   tput setaf 3|| tput AF 3    )
        blue=$(     tput setaf 4|| tput AF 4    )
        magenta=$(  tput setaf 5|| tput AF 5    )
        cyan=$(     tput setaf 6|| tput AF 6    )
    fi
    black=$(    tput setaf 0|| tput AF 0    )
    white=$(    tput setaf 7|| tput AF 7    )
    default=$(  tput op                     )
    eed=$(      tput ed     || tput cd      )   # Erase to end of display
    eel=$(      tput el     || tput ce      )   # Erase to end of line
    ebl=$(      tput el1    || tput cb      )   # Erase to beginning of line
    ewl=$eel$ebl                                # Erase whole line
  fi 3>&2 2>/dev/null ||:

  # shellcheck disable=SC2155,SC2034
  # bashsupport disable=BP2001,BP5006
  declare -g \
    LOGR_RESET=$(tput sgr0) \
    LOGR_COLOR_FG_BLACK=$(tput setaf 0) \
    LOGR_COLOR_FG_RED=$(tput setaf 1) \
    LOGR_COLOR_FG_GREEN=$(tput setaf 2) \
    LOGR_COLOR_FG_YELLOW=$(tput setaf 3) \
    LOGR_COLOR_FG_BLUE=$(tput setaf 4) \
    LOGR_COLOR_FG_MAGENTA=$(tput setaf 5) \
    LOGR_COLOR_FG_CYAN=$(tput setaf 6) \
    LOGR_COLOR_FG_WHITE=$(tput setaf 7) \
    LOGR_COLOR_FG_BRIGHT_BLACK=$(tput setaf 8) \
    LOGR_COLOR_FG_BRIGHT_RED=$(tput setaf 9) \
    LOGR_COLOR_FG_BRIGHT_GREEN=$(tput setaf 10) \
    LOGR_COLOR_FG_BRIGHT_YELLOW=$(tput setaf 11) \
    LOGR_COLOR_FG_BRIGHT_BLUE=$(tput setaf 12) \
    LOGR_COLOR_FG_BRIGHT_MAGENTA=$(tput setaf 13) \
    LOGR_COLOR_FG_BRIGHT_CYAN=$(tput setaf 14) \
    LOGR_COLOR_FG_BRIGHT_WHITE=$(tput setaf 15) \
    LOGR_CURSOR_END_MARGIN="$(tput hpa 0)" \
    LOGR_CURSOR_COLUMN_MARGIN="$(tput hpa 0)" \
    LOGR_CURSOR_COLUMN_NORMAL="$(tput hpa "${#LOGR_MARGIN_LEFT}")" \
    LOGR_CURSOR_SAVE=$(tput sc) \
    LOGR_CURSOR_RESTORE=$(tput rc) \
    LOGR_CURSOR_HIDE=$(tput civis) \
    LOGR_CURSOR_SHOW=$(tput cnorm)
  # shellcheck disable=SC2155,SC2034
  # bashsupport disable=BP2001,BP5006
  declare -g \
    LOGR_ICON_NEW='✱' \
    LOGR_ICON_ITEM='▪' \
    LOGR_FORMAT_ITEM='' \
    LOGR_ICON_LINK='↗' \
    LOGR_ICON_FILE='↗' \
    LOGR_ICON_TASK='☐' \
    LOGR_ICON_SUCCESS='✔' \
    LOGR_ICON_INFO='ℹ' \
    LOGR_ICON_WARN='⚠' \
    LOGR_ICON_ERROR='✘' \
    LOGR_ICON_FAIL='⚡'
  # shellcheck disable=SC2155,SC2034
  # bashsupport disable=BP2001,BP5006
  declare -g -n \
    LOGR_FORMAT_NEW=LOGR_COLOR_FG_YELLOW \
    LOGR_FORMAT_LINK=LOGR_COLOR_FG_BLUE \
    LOGR_FORMAT_FILE=LOGR_COLOR_FG_BLUE \
    LOGR_FORMAT_TASK=LOGR_COLOR_FG_BLUE \
    LOGR_FORMAT_SUCCESS=LOGR_COLOR_FG_GREEN \
    LOGR_FORMAT_INFO=LOGR_COLOR_FG_WHITE \
    LOGR_FORMAT_WARN=LOGR_COLOR_FG_BRIGHT_YELLOW \
    LOGR_FORMAT_ERROR=LOGR_COLOR_FG_RED \
    LOGR_FORMAT_FAIL=LOGR_COLOR_FG_RED

  [[ -n "${BATS_VERSION:-}" ]] || logr _init
}

main "$@"
