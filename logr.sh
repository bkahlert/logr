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
# bashsupport disable=BP5001
(return 2>/dev/null) || set -- "$@" "-!-"

# Indicates an occurred problem and exits.
# Globals:
#   FUNCNAME
# Arguments:
#   w - optional flag; if set only returns instead of exits
#   n - optional name of the failed unit (determined using FUNCNAME by default)
#   u - optional usage information; output is automatically preceded with the name
#   - - optional; used declare remaining arguments as positional arguments
#   * - arguments the original unit was called with
failr() {
  local code=$? failr_usage="[-n|--name NAME] [-u|--usage USAGE] [FORMAT [ARGS...]] [--] [INVOCATION...]"
  local name=${FUNCNAME[1]:-?} format=() usage print_call idx
  local -a stacktrace=()
  for idx in "${!BASH_LINENO[@]}"; do
    [ "${BASH_LINENO[idx]}" = 0 ] || stacktrace+=("${FUNCNAME[idx + 1]:-?}(${BASH_SOURCE[idx + 1]:-?}:${BASH_LINENO[idx]:-?})")
  done

  while (($#)); do
    case $1 in
    -n | --name)
      [ "${2-}" ] || failr "value of name missing" --usage "$failr_usage" -- "$@"
      name=$2 && shift 2
      ;;
    -u | --usage)
      [ "${2-}" ] || failr "value of usage missing" --usage "$failr_usage" -- "$@"
      usage=$2 && shift 2
      ;;
    -c | --code)
      [ "${2-}" ] || failr "value of code missing" --usage "$failr_usage" -- "$@"
      code=$2 && shift 2
      ;;
    --)
      print_call=true && shift
      break
      ;;
    *)
      format+=("$1") && shift
      ;;
    esac
  done

  local invocation="$name"
  if [ "${print_call-}" ]; then
    if [ $# -eq 0 ]; then
      invocation="${name} ${tty_italic}[no arguments]${tty_italic_end}"
    else
      invocation="${name} ${tty_underline}$*${tty_underline_end}"
    fi
  fi

  local formatted
  # shellcheck disable=SC2059
  [ "${#format[@]}" -eq 0 ] || printf -v formatted "${format[@]}"
  printf -v formatted '\n%s ✘ %s failed%s%s\n' "$tty_red" "$invocation" \
    "${format+: "$tty_bold${format[*]}$tty_stout_end"}" "$tty_reset"

  [ ${#stacktrace[@]} -eq 0 ] || formatted+="$(printf '     at %s\n' "${stacktrace[@]}")$LF"
  [ ! "${usage-}" ] || formatted+="   Usage: $name ${usage//$LF/$LF   }$LF"

  printf '%s\n' "$formatted" >&2

  if [ "${code:-0}" = 0 ]; then
    exit 1
  else
    exit "$code"
  fi
}

# Invokes a terminal function.
# Arguments:
#   v - same behavior as `printf -v`
#   * - args passed to the terminal function.
tty() {
  local args=() _tty_var usage="[-v VAR] FUNCTION [ARGS...]"
  while (($#)); do
    case $1 in
    -v)
      [ "${2-}" ] || failr "value of var missing" --usage "$usage" -- "$@"
      _tty_var=$2
      shift 2
      ;;
    *)
      args+=("$1")
      shift
      ;;
    esac
  done
  set -- "${args[@]}"
  [ $# = 0 ] && failr "function missing" --usage "$usage" -- "$@"

  local _tty_val
  case $1 in
  _init)
    shift
    # bashsupport disable=BP2001
    # shellcheck disable=SC2034
    declare -g tty_connected='' tty_alt='' tty_alt_end='' tty_hpa0='' tty_hide='' tty_show='' tty_save='' tty_load='' \
      tty_dim='' tty_bold='' tty_stout='' tty_stout_end='' tty_underline='' tty_underline_end='' \
      tty_reset='' tty_blink='' tty_italic='' tty_italic_end='' tty_black='' tty_white='' \
      tty_bright_black='' tty_bright_white='' tty_default='' tty_eed='' tty_eel='' tty_ebl='' tty_ewl='' \
      tty_red='' tty_green='' tty_yellow='' tty_blue='' tty_magenta='' tty_cyan='' \
      tty_bright_red='' tty_bright_green='' tty_bright_yellow='' tty_bright_blue='' tty_bright_magenta='' tty_bright_cyan=''

    # escape sequences if terminal is connected
    # shellcheck disable=SC2015,SC2034
    [ -t 2 ] && [ ! "${TERM-}" = dumb ] && {
      # updates COLUMNS and LINES and calls optional callback with these dimensions
      tty_change_handler() {
        COLUMNS=$({ tput cols || tput co; }) && LINES=$({ tput lines || tput li; })
        [ ! "${1-}" ] || [ ! "$(type -t "$1")" = function ] || "$1" "$COLUMNS" "$LINES"
      }
      trap 'tty_change_handler tty_changed' WINCH # calls 'tty_changed' if defined and dimensions changed
      tty_change_handler tty_init 2>&3            # calls 'tty_init' if defined
      tty_connected=true                          # if set, signifies a connected terminal
      tty_alt=$(tput smcup || tput ti)            # start alt display
      tty_alt_end=$(tput rmcup || tput te)        # end alt display
      tty_hpa0=$(tput hpa 0)                      # set horizontal abs pos 0
      tty_hpa_margin=$(tput hpa ${#MARGIN})       # set horizontal abs end of margin
      tty_hide=$(tput civis || tput vi)           # hide cursor
      tty_show=$(tput cnorm || tput ve)           # show cursor
      tty_save=$(tput sc)                         # save cursor
      tty_load=$(tput rc)                         # load cursor
      tty_dim=$(tput dim || tput mh)              # start dim
      tty_bold=$(tput bold || tput md)            # start bold
      tty_stout=$(tput smso || tput so)           # start stand-out
      tty_stout_end=$(tput rmso || tput se)       # end stand-out
      tty_underline=$(tput smul || tput us)       # start underline
      tty_underline_end=$(tput rmul || tput ue)   # end underline
      tty_reset=$(tput sgr0 || tput me)           # reset cursor
      tty_blink=$(tput blink || tput mb)          # start blinking
      tty_italic=$(tput sitm || tput ZH)          # start italic
      tty_italic_end=$(tput ritm || tput ZR)      # end italic

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
      tty_eed=$(tput ed || tput cd)  # erase to end of display
      tty_eel=$(tput el || tput ce)  # erase to end of line
      tty_ebl=$(tput el1 || tput cb) # erase to beginning of line
      tty_ewl=$tty_eel$tty_ebl       # erase whole line
    } 3>&2 2>/dev/null || true
    return
    ;;

  cursor)
    usage="${usage%FUNCTION*}$1 show | hide"
    shift
    [ $# -eq 1 ] || failr "command missing" --usage "$usage" -- "$@"
    case $1 in
    show)
      shift
      _tty_val="$tty_show"
      ;;
    hide)
      shift
      _tty_val="$tty_hide"
      ;;
    *)
      failr "unknown command" --usage "$usage" -- "$@"
      ;;
    esac
    ;;

  *)
    failr "unknown command" --usage "$usage" -- "$@"
    ;;
  esac

#      printf '%s' "$(tput vpa $((LINES-2)))" # TODO
#      printf '%s' "$tty_hpa0" # TODO

  if [ "${_tty_var-}" ]; then
    printf -v "$_tty_var" '%s' "$_tty_val"
  else
    printf '%s' "$_tty_val"
  fi
}

# Invokes a utility function.
# Arguments:
#   v - same behavior as `printf -v`
#   n - if set, appends a newline
#   * - args passed to the utility function.
util() {
  local args=() _util_var _util_newline usage="[-v VAR] [-n|--newline] UTIL [ARGS...]"
  while (($#)); do
    case $1 in
    -v)
      [ "${2-}" ] || failr "value of var missing" --usage "$usage" -- "$@"
      _util_var=$2
      shift 2
      ;;
    -n | --newline)
      _util_newline=true
      shift
      ;;
    *)
      args+=("$1")
      shift
      ;;
    esac
  done
  set -- "${args[@]}"
  [ $# = 0 ] && failr "command missing" --usage "$usage" -- "$@"

  # utilities
  local util_text
  case $1 in
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
    [ $# -eq 1 ] || failr "text missing" --usage "$usage" -- "$@"

    local -i available_width=${#MARGIN} text_width="${util_center_width:-${#1}}"
    local -i lpad=$(((available_width - text_width) / 2))
    [ "$lpad" -gt 0 ] || lpad=0
    local -i rpad=$((available_width - text_width - lpad))
    [ "$rpad" -gt 0 ] || rpad=0

    printf -v util_text "%*s%s%*s" "$lpad" '' "$1" "$rpad" ''
    ;;

  icon)
    args=() usage="${usage%UTIL*}$1 [-c|--center] ICON"
    shift
    local _icon_center
    while (($#)); do
      case $1 in
      -c | --center)
        _icon_center=true
        shift
        ;;
      *)
        args+=("$1")
        shift
        ;;
      esac
    done
    set -- "${args[@]}"
    [ $# -eq 1 ] || failr "icon missing" --usage "$usage" -- "$@"
    local _icon_icon _icon_template
    _icon_icon=${logr_icons[${1,,}]-'?'}
    _icon_template=${logr_templates[${1,,}]-'%s'}
    [ ! ${_icon_center-} ] || util center -v _icon_icon "$_icon_icon"
    # shellcheck disable=SC2059
    printf -v util_text "$_icon_template" "$_icon_icon"
    ;;

  inline)
    usage="${usage%UTIL*}$1 FORMAT [ARGS...]"
    shift

    [ $# -ge 1 ] || failr "format missing" --usage "$usage" -- "$@"

    # shellcheck disable=SC2059
    local text && printf -v text "${@}"
    text=${text#$LF}
    text=${text%$LF}
    text=${text//$LF*$LF/; ...; }
    text=${text//$LF/; }

    util_text="$text"
    ;;

  # fits the given pattern in the current row by truncating the middle with ... if necessary
  fit)
    shift
    local truncation=' ... ' slack=5
    # shellcheck disable=SC2059
    local _fit_text && printf -v _fit_text "$@"
    local _fit_columns=$((${COLUMNS:-80} - ${#MARGIN} - "$slack"))
    [ "$_fit_columns" -gt 20 ] || _fit_columns=20
    if [ "$_fit_columns" -lt "${#_fit_text}" ]; then
      local _fit_half=$(((_fit_columns - ${#truncation} - 1) / 2))
      local _fit_left=${_fit_text:0:_fit_half} _fit_right=${_fit_text:$((${#_fit_text} - _fit_half)):_fit_half}
      printf -v util_text "%s%s%s" "${_fit_left%% }" "$truncation" "${_fit_right## }"
    else
      util_text=$_fit_text
    fi
    ;;

  fit_concat)
    usage="${usage%UTIL*}$1 ICON TEXT1 TEXT2"
    shift
    [ $# -eq 3 ] || failr --usage "$usage" -- "$@"

    local _fit_concat_icon && util -v _fit_concat_icon icon --center "$1" && shift
    local _fit_concat_text
    if [ "$1" ] && [ "$2" ]; then
      _fit_concat_text="$1$_fit_concat_icon$2"
    else
      _fit_concat_text="$1$2"
    fi

    _fit_concat_text=${_fit_concat_text//$_fit_concat_icon/$''}
    util fit -v _fit_concat_text "$_fit_concat_text"
    _fit_concat_text=${_fit_concat_text//$''/$_fit_concat_icon}

    util_text=$_fit_concat_text
    ;;

  # prints on the margin without changing the cursor
  print_margin)
    usage="${usage%UTIL*}$1 TEXT"
    shift
    [ $# -eq 1 ] || failr "text missing" --usage "$usage" -- "$@"
    printf -v util_text '%s%s%s%s' "$tty_save" "$tty_hpa0" "${1?text missing}" "$tty_load"
    ;;

  # prints the optional icon and text
  print)
    args=() usage="${usage%UTIL*}$1 [-i|--icon ICON] [TEXT...]"
    shift
    local print_icon="$MARGIN"
    while (($#)); do
      case $1 in
      -i | --icon)
        [ "${2-}" ] || usage
        util -v print_icon icon --center "$2"
        shift 2
        ;;
      --skip-icon)
        print_icon="${tty_hpa_margin-}"
        shift
        ;;
      *)
        args+=("$1")
        shift
        ;;
      esac
    done
    set -- "${args[@]}"

    local text=''
    # shellcheck disable=SC2059
    [ $# -eq 0 ] || printf -v text "$@"
    text=${text//$LF/$LF$MARGIN}
    printf -v util_text '%s%s' "$print_icon" "$text"
    ;;

  prefix)
    args=() usage="${usage%UTIL*}$1 [--config CONFIG] [FORMAT [ARGS...]]"
    local colors=(black cyan blue green yellow magenta red) config
    shift
    while (($#)); do
      case $1 in
      --config)
        [ "${2-}" ] || failr "value for config missing" --usage "$usage" -- "$@"
        config=$2
        shift 2
        ;;
      *)
        args+=("$1")
        shift
        ;;
      esac
    done
    set -- "${args[@]}"

    local prefix='' color props char state
    while IFS=' ' read -r -d: -a props || props=''; do
      [ "${#colors[@]}" -gt 0 ] || break
      color=${colors[0]} char=░ state=1 && colors=("${colors[@]:1}")
      for prop in "${props[@]}"; do
        [ "${prop-}" ] || continue
        case $prop in
        c=* | char=*)
          char=${prop#*=}
          continue
          ;;
        s=* | state=*)
          state=${prop#*=}
          continue
          ;;
        esac
        failr "unknown prop '$prop'; expected colon (:) separated list of space ( ) separated key=value pairs"
      done

      [ "${char-}" ] || continue

      case $state in
      0)
        color="tty_$color"
        ;;
      *)
        color="tty_bright_$color"
        ;;
      esac
      prefix+="${!color}$char$tty_reset"
    done <<<"${config-} :"

    # shellcheck disable=SC2059
    local parts=("$prefix") && [ $# -eq 0 ] || printf -v parts[1] "$@"
    printf -v util_text %s "${parts[*]}"
    ;;

  reprint)
    args=() usage="${usage%UTIL*}$1 [-i|--icon ICON] FORMAT [ARGS...]"
    shift
    local _reprint_icon=${tty_hpa_margin-}
    [ "$tty_connected" ] || util -v _reprint_icon icon --center running
    while (($#)); do
      case $1 in
      --icon)
        [ "${2-}" ] || usage
        util -v _reprint_icon icon --center "$2"
        shift 2
        ;;
      *)
        args+=("$1")
        shift
        ;;
      esac
    done
    set -- "${args[@]}"

    # shellcheck disable=SC2059
    local _reprint && printf -v _reprint "$@"
    if [ "$tty_connected" ]; then
      printf -v util_text '%s%s%s%s' "$tty_hpa0" "$_reprint_icon" "$_reprint" "$tty_eel"
    else
      printf -v util_text '%s%s' "$_reprint_icon" "$_reprint"
      _util_newline=true
    fi
    ;;

  # colored banner words
  words)
    shift
    # shellcheck disable=SC2059
    local _words_text && [ $# -eq 0 ] || printf -v _words_text "$@"
    # shellcheck disable=SC2015
    local -a _words=() && [ ! "${_words_text-}" ] || IFS=' ' read -r -a _words <<<"$_words_text"
    local -a _colored=()
    local i
    for i in "${!_words[@]}"; do
      # color all but first words bright magenta
      if [ "$i" -gt 0 ]; then
        _colored+=("$tty_bright_magenta${_words[$i]^^}$tty_reset")
        continue
      fi

      # split first word camelCase; first word -> bright cyan; rest -> cyan
      # shellcheck disable=SC2001
      local -a _words0 && read -r -a _words0 <<<"$(echo "${_words[$i]}" | sed -e 's/\([A-Z]\)/ \1/g')"
      if [ ${#_words0[@]} -gt 0 ]; then
        _colored+=("$tty_bright_cyan${_words0[0]^^}$tty_reset")
        if [ ${#_words0[@]} -gt 1 ]; then
          local _word=${_words0[*]:1}
          _word=${_word// /}
          _colored+=("$tty_cyan${_word^^}$tty_reset")
        fi
      fi
    done
    printf -v util_text %s "${_colored[*]}"
    ;;

  *)
    failr "unknown command" --usage "$usage" -- "$@"
    ;;
  esac

  # output
  [ ! "${_util_newline-}" ] || printf -v "util_text" '%s\n' "$util_text"
  if [ "${_util_var-}" ]; then
    printf -v "$_util_var" '%s' "$util_text"
  else
    printf '%s' "$util_text"
  fi
}

# Invokes a spinner function.
# Arguments:
#   * - args passed to the spinner function.
spinner() {
  [ "$tty_connected" ] || return 0
  local usage="start | is_active | stop"
  [ $# -gt 0 ] || failr "command missing" --usage "$usage" -- "$@"
  case $1 in
  start)
    shift
    [ $# = 0 ] || failr "unexpected argument" --usage "$usage" -- "$@"
    spinner stop
    spinner _spin &
    ;;
  is_active)
    shift
    [ $# = 0 ] || failr "unexpected argument" --usage "$usage" -- "$@"
    jobs -p 'spinner _spin' >/dev/null 2>/dev/null
    ;;
  stop)
    shift
    [ $# = 0 ] || failr "unexpected argument" --usage "$usage" -- "$@"
    if spinner is_active; then
      jobs -p 'spinner _spin' | xargs -r kill
    fi
    ;;
  _spin)
    shift
    [ $# = 0 ] || failr "unexpected argument" --usage "$usage" -- "$@"
    local -a frames=()
    read -ra frames <<<"⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏"
    local _i
    for _i in "${!frames[@]}"; do
      util center -v "frames[$_i]" "${frames[$_i]}"
    done
    while true; do
      for _i in "${!frames[@]}"; do
        util print_margin "$tty_bright_yellow${frames[$_i]}$tty_load"
        sleep 0.10
      done
    done
    ;;
  *)
    failr "unknown command" --usage "$usage" -- "$@"
    ;;
  esac
}

# Prints a colorful banner.
# Arguments:
#   * - words
banr() {
  local -a args=()
  local config
  while (($#)); do
    case $1 in
    --config)
      [ "${2-}" ] || failr "value of config missing" --usage "[--config CONFIG] [WORDS]"
      config=$2
      shift 2
      ;;
    *)
      args+=("$1")
      shift
      ;;
    esac
  done

  # shellcheck disable=SC2015
  local text && [ "${#args[@]}" -eq 0 ] || util -v text words ${args+"${args[*]}"}
  util --newline prefix ${config+--config "$config"} ${text+"${text}"}
}

# Logs according to the given type.
# Arguments:
#   1 - command
#   * - command arguments
# Returns:
#   0 - success
#   1 - error
#   * - signal
logr() {
  local usage="COMMAND [ARGS...]"
  case ${1:-'_help'} in
  _help)
    printf '\n   logr v%s\n\n   Usage: logr %s%s' "$LOGR_VERSION" "$usage" '

   Commands:
     new         Log a new item
     item        Log an item
     list        Log a list of items
     link        Log a link
     file        Log a file link

     success     Log a success message
     info        Log an information
     warn        Log a warning
     error       Log an error
     fail        Log an error and terminate
'
    exit 0
    ;;
  _init)
    shift
    trap 'logr _cleanup || true; printf "\n"; logr error "${0##*/} aborted"; trap - INT; kill -s INT "$$"' INT
    trap 'logr _abort $?' TERM
    trap 'logr _cleanup' EXIT
    tty cursor hide >&2
    ;;
  _cleanup)
    shift
    tty cursor show
    local job_pid
    for job_pid in $(jobs -p); do
      kill "$job_pid" &>/dev/null || true
    done
    ;;
  _abort)
    shift
    local code=${1:-1}
    logr _cleanup
    failr --name "${0##*/}" --code "$code" "Aborted" || true
    ;;

  new | item | success | info | warn)
    util --newline print --icon "$1" "${@:2}"
    ;;
  error | fail)
    util --newline print --icon "$1" "${@:2}" >&2
    [ ! "$1" = "error" ] || return 1
    [ ! "$1" = "fail" ] || exit 1
    ;;
  list)
    shift
    local item
    for item in "$@"; do logr item "$item"; done
    ;;
  link)
    usage="${usage%COMMAND*}$1 URL [TEXT]"
    shift
    [ $# -ge "1" ] || failr "url missing" --usage "$usage" -- "$@"
    local url="$1" text=${2:-$1}
    # shellcheck disable=SC1003
    util --newline print --icon link '\e]8;;%s\e\\%s\e]8;;\e\\' "$url" "$text"
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
    local url="file://$path" text=${2:-file://$path}
    # shellcheck disable=SC1003
    util --newline print --icon file '\e]8;;%s\e\\%s\e]8;;\e\\' "$url" "$text"
    ;;
  running)
    util --newline print --icon "$1" "${@:2}"
    ;;
  task)
    usage="${usage%COMMAND*}$1 [FORMAT [ARGS...]] [-- COMMAND [ARGS...]]"
    shift
    local format=()
    while (($#)); do
      case $1 in
      --)
        shift
        break
        ;;
      *)
        format+=("$1")
        shift
        ;;
      esac
    done
    local -a cmdline=("$@")

    local logr_task
    if [ "${#format[@]}" -eq 0 ]; then
      [ "${#cmdline[@]}" -gt 0 ] || failr "format or command missing" --usage "$usage" -- "$@"
      util inline -v logr_task "${cmdline[*]}"
    else
      # shellcheck disable=SC2059
      util inline -v logr_task "${format[@]}"
    fi

    if [ "${#cmdline[@]}" -eq 0 ]; then
      util --newline print --icon task "$logr_task"
      return 0
    fi

    local logr_tasks && util -v logr_tasks fit_concat nest "$logr_parent_tasks" "$logr_task"

    local task_file && task_file=${TMPDIR:-/tmp}/logr.$$.task
    local log_file && log_file=${TMPDIR:-/tmp}/logr.$$.log

    local task_exit_status=0
    if [ ! "$logr_parent_tasks" ]; then
      [ ! -f "$task_file" ] || rm -- "$task_file"
      [ ! -f "$log_file" ] || rm -- "$log_file"
      util reprint "$logr_tasks"
      spinner start
      # run command line; redirect stdout+stderr to log_file; provide FD3 and FD4 as means to still print
      (logr_parent_tasks=$logr_tasks "${cmdline[@]}" 3>&1 1>"$log_file" 4>&2 2>"$log_file") || task_exit_status=$?
    else
      util reprint "$logr_tasks" >&3
      # run command line; redirects from parent task already apply
      (logr_parent_tasks=$logr_tasks "${cmdline[@]}") || task_exit_status=$?
    fi

    if [ ! "$task_exit_status" -eq 0 ] && [ ! -f "$task_file" ]; then
      printf %s "$logr_tasks" >"$task_file"
    fi

    # pass exit code up to initial task
    if [ "$logr_parent_tasks" ]; then
      [ "$task_exit_status" -eq 0 ] || exit "$task_exit_status"
    else
      # --- only initial task here
      spinner stop

      # error
      if [ ! "$task_exit_status" -eq 0 ]; then
        util --newline reprint --icon error "$(cat "$task_file")"
        sed \
          -e 's/[\[(][(0-9;]*[a-zA-Z]//g;' \
          -e 's/^/'"$MARGIN$tty_red"'/;' \
          -e 's/$/'"$tty_reset"'/;' \
          "$log_file"
        exit $task_exit_status
      fi

      # success
      # erase what has been printed on same line by printing task_line again
      util --newline reprint --icon success "$logr_tasks"
    fi
    ;;
  *)
    failr "unknown command" --usage "$usage" -- "$@"
    ;;
  esac
}

# Prompts for user input of the specified type.
# Arguments:
#   1 - type
#   * - type arguments
# Returns:
#   0 - success
#   1 - error
#   * - signal
prompt4() {
  local usage="TYPE [ARGS...]"
  case ${1:-'_help'} in
  _help | -h | --help)
    printf '\n   prompt4 v%s\n\n   Usage: prompt4 %s%s' "$LOGR_VERSION" "$usage" '

 Type:
   continue    "Do you want to continue?"
'
    exit 0
    ;;
  Yn)
    shift
    local -a args=()
    local _arg _yn_question="Do you want to continue?" _yn_answer
    for _arg in "$@"; do
      if [ "${_arg-}" = - ]; then
        args+=("$_yn_question")
      else
        args+=("${_arg-}")
      fi
    done
    set -- "${args[@]}"

    if [ $# -gt 0 ]; then
      # shellcheck disable=SC2059
      printf -v _yn_question "$@"
    fi
    util print '\n%s%s %s %s' "$tty_bold" "${_yn_question%%$'\n'}" "[Y/n]" "$tty_stout_end"

    if [ -t 0 ]; then
      local _yn_tty_settings
      _yn_tty_settings=$(stty -g)
      # shellcheck disable=SC2064
      trap "stty '$_yn_tty_settings'" EXIT
      trap "_yn_answer=n" INT TERM
      stty raw isig || true
      _yn_answer=$(head -c 1) || true
      stty "${_yn_tty_settings}" || true
      trap - INT TERM EXIT
    else
      _yn_answer=$(head -c 1) || true
    fi

    case $_yn_answer in
    n* | **)
      local _icon && util -v _icon icon --center error
      util print_margin "$_icon"
      printf '%s%s%s\n' "$tty_dim" "no" "$tty_reset"
      exit 1
      ;;
    *)
      local _icon && util -v _icon icon --center success
      util print_margin "$_icon"
      printf '%s%s%s\n' "$tty_dim" "yes" "$tty_reset"
      ;;
    esac
    ;;
  *)
    failr "unknown type" --usage "$usage" -- "$@"
    ;;
  esac
}

# Kommons' tracer [1] inspired helper function that supports print debugging [2]
# by printing details about the passed arguments.
# Arguments:
#   * - arguments to print debugging information for
# References:
#   1 - https://github.com/bkahlert/kommons/blob/35e2ac1c4246decdf7e7a1160bfdd5c9e28fd066/src/commonMain/kotlin/com/bkahlert/kommons/debug/Insights.kt#L149
#   2 - https://en.wikipedia.org/wiki/Debugging#Print_debugging
tracr() {
  local debug="$tty_cyan%s$tty_reset"
  local quote && printf -v quote "$debug%%s$debug" "'" "'"

  # shellcheck disable=SC2059
  local argc && printf -v argc "$debug" "$#"

  # shellcheck disable=SC2059
  [ $# -eq 0 ] || printf "$quote " "$@"
  local location && [ ! "${BASH_SOURCE[1]-}" ] || location="${BASH_SOURCE[1]}:${BASH_LINENO[0]}"
  local prefix_length && printf -v prefix_length " ! %s %s" "$location" "$#" && prefix_length=$(( ${#prefix_length} + 8 ))
  printf %s "$argc" "   " "$(tput hpa 80)" "$(logr file "$location")"
  printf '\n'
}

# Initializes environment
main() {
  TMPDIR=${TMPDIR:-/tmp} TMPDIR=${TMPDIR%/}

  # bashsupport disable=BP5006
  declare -g -r LOGR_VERSION=0.1.0 LF=$'\n'
  # bashsupport disable=BP5006
  declare -g MARGIN='   '

  tty _init

  declare -A -g -r logr_icons=(
    ['new']='✱'
    ['item']='▪'
    ['link']='↗'
    ['file']='↗'
    ['task']='☐'
    ['nest']='❱'
    ['running']='⚙' # no terminal
    #'running'-> spinner
    ['success']='✔'
    ['info']='ℹ'
    ['warn']='⚠'
    ['error']='✘'
    ['fail']='⚡'
  )

  declare -g logr_parent_tasks=''

  local r=$tty_reset
  declare -A -g -r logr_templates=(
    ['new']="${tty_yellow}%s$r"
    ['link']="${tty_blue}%s$r"
    ['file']="${tty_blue}%s$r"
    ['task']="${tty_blue}%s$r"
    ['nest']="${tty_yellow}%s$r"
    ['running']="${tty_yellow}%s$r"
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

  require_shopt globstar            # ** matches all files and any number of dirs and sub dirs
  require_shopt checkjobs           # check for running jobs before exiting
  stty -echoctl 2>/dev/null || true # don't echo control characters in hat notation (e.g. `^C`)

  [ ! "${1-}" = -h ] || logr _help
  [ ! "${1-}" = --help ] || logr _help
  [ "${BATS_VERSION-}" ] || logr _init
  [[ " $* " == *" -!- "* ]] || return 0

  # prints source-instead-of-execute error
  # shellcheck disable=SC2016
  usage() {
    printf '\n'
    logr error "To use logr you need to source it at the top of your script." || true
    printf '\n'
    logr info 'If logr is on your $PATH type:
source logr.sh
'
    logr info 'To source logr from the same directory as your script add:
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)/logr.sh"
'
    logr info 'To source logr relative to your script add:
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)/RELATIVE_PATH/logr.sh"
'
  }

  usage

  # Prints the specified text as a section headline.
  # Arguments:
  #   1 - headline
  #   2 - separator
  # bashsupport disable=BP5005
  SECTION() {
    printf "%s\n\n ━━━━━━━ %s%s\n" "$tty_white" "${*//-/━}" "$tty_reset"
  }

  SECTION FEATURES -------------------------------------------------------------

  SECTION banr -----------------------------------------------------------------
  banr
  banr foo
  banr fooBar
  banr fooBar baz
  banr foo bar baz

  SECTION logr -----------------------------------------------------------------
  logr new "new item"
  logr item "item"
  logr list "item 1" "item 2" "item 3"
  logr link "https://github.com/bkahlert/logr"
  logr link "https://example.com" "link text"
  logr file "logr.sh" --line 300 --column 10
  logr success "success"
  logr info "info"
  logr warn "warning"
  logr error "error" \
    || (logr fail "failure") || true

  logr task "task"
  logr running "running task"
  logr task "task message and cmdline" -- sleep 2
  (logr task -- bash -c '
echo foo && sleep 1
echo bar >&2 && sleep 1
echo baz >&2 && sleep 1
exit 2
') || true

  # vanilla recursion
  foo() {
    logr info "foo args: $*"
    [ "$1" -eq 0 ] || foo $(($1 - 1)) "$2"
    sleep 1
    [ ! "$1" = "$2" ] || exit 1
  }
  logr task -- foo 3 -
  (logr task -- foo 3 2) || true

  # logr task recursion
  bar() {
    logr info "bar args: $*"
    [ "$1" -eq 0 ] || logr task -- bar $(($1 - 1)) "$2"
    sleep 1
    [ ! "$1" = "$2" ] || exit 1
  }
  logr task -- bar 3 -
  (logr task -- bar 3 2) || true

  # provoking line overflow
  supercalifragilisticexpialidocious() {
    local long="${FUNCNAME[0]}"
    sleep 1
    logr task -- logr task -- echo "$long $long $long $long $long"
    sleep 1
    logr task -- logr task -- echo "$long $long $long $long $long"
    sleep 1
  }
  logr task "running supercalifragilisticexpialidocious without breaking output" -- supercalifragilisticexpialidocious

  sleep 1

  SECTION prompt4 --------------------------------------------------------------

  echo y | prompt4 Yn || true
  echo y | prompt4 Yn "Single line" || true
  echo y | prompt4 Yn "%s\n%s\n" "Multi-" "line" || true
  echo y | prompt4 Yn "%s\n" "Multi-" "line" - || true
  (echo n | prompt4 Yn) || true
  (echo n | prompt4 Yn "Single line") || true
  (echo n | prompt4 Yn "%s\n%s\n" "Multi-" "line") || true
  (echo n | prompt4 Yn "%s\n" "Multi-" "line" -) || true

  SECTION failr - error message util -------------------------------------------
  (failr) || true
  (failr --) || true
  (
    # pretends to need argument
    foo() {
      [ "$1" = baz ] || failr "baz expected" --usage "baz" -- "$*"
    }
    foo bar
  ) || true

  SECTION escape sequences -----------------------------------------------------
  for color in BLACK RED GREEN YELLOW BLUE MAGENTA CYAN WHITE; do
    local tty_bright_color="tty_bright_${color,,}"
    local tty_color="tty_${color,,}"
    printf "%10s %sNORMAL%sDIMMED%s %sBRIGHT%sDIMMED%s\n" "${color^^}" \
      "${!tty_color}" "$tty_dim" "$tty_reset" \
      "${!tty_bright_color}" "$tty_dim" "$tty_reset"
  done

  SECTION util - misc utilities ------------------------------------------------

  SECTION inline
  util --newline inline 'foo'
  util --newline inline '
foo
bar
'
  util --newline inline '
foo
bar
baz
'
  SECTION center
  util center '' && echo "|"
  util center '✘' && echo "|"
  util center -w 2 '👐' && echo "|"
  declare var
  util center -v var '12' && echo "$var|"
  util center '123' && echo "|"
  util center '1234' && echo "|"

  SECTION icon
  printf ' ' && util icon success
  printf ' ' && util icon warn
  printf ' ' && util -v var icon error && echo "$var"
  printf '%s' '->' && util icon --center new && printf '%s\n' '<-'

  SECTION print_margin
  local num
  for num in 0 1 2 3 4 5; do
    printf '%d' "$num"
    sleep 0.05
    util print_margin "⠤⠶⠿"
    sleep 0.05
  done
  echo

  SECTION print
  util --newline print --icon success 'existing icon + text'
  util --newline print 'text only'
  util --newline print --icon not-exists 'not existing icon + text'

  SECTION reprint
  util print --icon success 'existing-icon + text' && sleep 0.3 && util --newline reprint --icon success " -> icon + text updated"
  util print 'text-only' && sleep 0.3 && util --newline reprint --icon success
  util print --icon not-exists 'not-existing icon + text' && sleep 0.3 && util --newline reprint " -> text updated"

  SECTION tracr ----------------------------------------------------------------
  tracr
  tracr foo
  tracr foo bar

  SECTION END OF FEATURES ----------------------------------------------------

  usage
  exit 1
}

main "$@"
