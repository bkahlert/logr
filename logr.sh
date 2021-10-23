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
  local code=$? failr_usage="[-n|--name NAME] [-u|--usage USAGE] [FORMAT [ARGS...]] [--] [INVOCATION...]" && [ ! ${code-} = 0 ] || code=1
  local warn name=${FUNCNAME[1]:-?} format=() usage print_call idx
  local -a stacktrace=()
  for idx in "${!BASH_LINENO[@]}"; do
    [ "${BASH_LINENO[idx]}" = 0 ] || stacktrace+=("${FUNCNAME[idx + 1]:-?}(${BASH_SOURCE[idx + 1]:-?}:${BASH_LINENO[idx]:-?})")
  done

  while (($#)); do
    case $1 in
      -w | --warn)
        warn=true && shift
        ;;
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

  local invocation=$name
  if [ "${print_call-}" ]; then
    if [ $# -eq 0 ]; then
      invocation+=" ${esc_italic-}[no arguments]${esc_italic_end-}"
    else
      printf -v invocation " ${esc_underline-}%q${esc_underline_end-}" "$@"
      invocation="$name$invocation"
    fi
  fi

  # shellcheck disable=SC2059
  local formatted && [ "${#format[@]}" -eq 0 ] || printf -v formatted "${format[@]}"
  local color="${esc_red-}" && [ ! "${warn-}" = true ] || color="${esc_yellow-}"
  local icon="${logr_icons['error']}" && [ ! "${warn-}" = true ] || icon="${logr_icons['warn']}"

  printf -v formatted '\n%s %s %s failed%s%s\n' "$color" "$icon" "$invocation" \
    "${format+: "${esc_bold-}${format[*]}${esc_stout_end-}"}" "${esc_reset-}"

  [ ${#stacktrace[@]} -eq 0 ] || formatted+="$(printf '     at %s\n' "${stacktrace[@]}")$LF"
  [ ! "${usage-}" ] || formatted+="   Usage: $name ${usage//$LF/$LF   }$LF"

  printf '%s\n' "$formatted" >&2

  [ "${warn-}" = true ] || exit "${code:-1}"
  return "${code:-1}"
}

# bashsupport disable=BP2001
# Prints the escape sequences of the requested capabilities to STDERR.
# Arguments:
#   init - initializes internal structures
#   v - same behavior as `printf -v`
#   * - capabilities
esc() {
  local _esc_var _esc_val='' usage="[--init] [-v VAR] [CAPABILITIES...]"
  while (($#)); do
    case $1 in
      --init)
        shift
        # escape sequences if terminal is connected
        # shellcheck disable=SC2015,SC2034
        [ -t 2 ] && [ ! "${TERM-}" = dumb ] && {
          # updates COLUMNS and LINES and calls optional callback with these dimensions
          tty_change_handler() {
            COLUMNS=$({ tput cols || tput co; }) && LINES=$({ tput lines || tput li; })
            [ ! "${1-}" ] || [ ! "$(type -t "$1")" = function ] || "$1" "$COLUMNS" "$LINES"
          }
          trap 'tty_change_handler tty_changed' WINCH      # calls 'tty_changed' if defined and dimensions changed
          tty_change_handler tty_init 2>&3                 # calls 'tty_init' if defined
          tty_connected=true                               # if set, signifies a connected terminal
          esc_alt=$(tput smcup || tput ti)                 # start alt display
          esc_alt_end=$(tput rmcup || tput te)             # end alt display
          esc_scroll_up=$(tput indn 1 || tput SF 1)        # entire display is moved up, new line(s) at bottom
          esc_hpa0=$(tput hpa 0 || tput ch 0)              # set horizontal abs pos 0
          esc_hpa1=$(tput hpa 1 || tput ch 1)              # set horizontal abs pos 1
          esc_hpa_margin=$(tput hpa ${#MARGIN})            # set horizontal abs end of margin
          esc_cuu1=$(tput cuu 1 || tput cuu1 || tput up)   # move up one line; stop at edge of screen
          esc_cud1=$(tput cud 1 || tput cud1 || tput 'do') # move down one line; stop at edge of screen
          esc_cuf1=$(tput cuf 1 || tput cuf1 || tput nd)   # move right one pos; stop at edge of screen
          esc_cub1=$(tput cub 1 || tput cub1 || tput le)   # move left one pos; stop at edge of screen
          esc_cursor_hide=$(tput civis || tput vi)         # hide cursor
          esc_cursor_show=$(tput cnorm || tput ve)         # show cursor
          esc_save=$(tput sc)                              # save cursor
          esc_load=$(tput rc)                              # load cursor
          esc_dim=$(tput dim || tput mh)                   # start dim
          esc_bold=$(tput bold || tput md)                 # start bold
          esc_stout=$(tput smso || tput so)                # start stand-out
          esc_stout_end=$(tput rmso || tput se)            # end stand-out
          esc_underline=$(tput smul || tput us)            # start underline
          esc_underline_end=$(tput rmul || tput ue)        # end underline
          esc_reset=$(tput sgr0 || tput me)                # reset cursor
          esc_blink=$(tput blink || tput mb)               # start blinking
          esc_italic=$(tput sitm || tput ZH)               # start italic
          esc_italic_end=$(tput ritm || tput ZR)           # end italic
          esc_colors=$(tput colors || tput Co)             # number of colors

          local -A colors=(['black']=0 ['red']=1 ['green']=2 ['yellow']=3 ['blue']=4 ['magenta']=5 ['cyan']=6 ['white']=7)
          local index name bright_name bg_name bg_bright_name
          # shellcheck disable=SC2059
          for color in "${!colors[@]}"; do
            [ "$color" = black ] || [ "$color" = white ] || [[ $TERM != *-m ]] || continue
            index=${colors["$color"]}
            name=esc_$color bright_name=esc_bright_$color bg_name=esc_bg_$color bg_bright_name=esc_bg_bright_$color
            printf -v "$name" "$(tput setaf "$index" || tput AF "$index")"
            printf -v "$bg_name" "$(tput setab "$index" || tput AB "$index")"
            if [ "$esc_colors" -gt 8 ]; then
              printf -v "$bright_name" "$(tput setaf "$((index + 8))" || tput AF "$((index + 8))")"
              printf -v "$bg_bright_name" "$(tput setab "$((index + 8))" || tput AB "$((index + 8))")"
            else
              printf -v "$bright_name" "$esc_bold${!name}"
              printf -v "$bg_bright_name" "$esc_bold${!bg_name}"
            fi
          done

          esc_default=$(tput op)
          esc_eed=$(tput ed || tput cd)  # erase to end of display
          esc_eel=$(tput el || tput ce)  # erase to end of line
          esc_ebl=$(tput el1 || tput cb) # erase to beginning of line
          esc_ewl=${esc_eel-}${esc_ebl-} # erase whole line
        } 3>&2 2>/dev/null || true
        ;;
      -v)
        [ "${2-}" ] || failr "value of var missing" --usage "$usage" -- "$@"
        _esc_var=$2 && shift 2
        ;;
      *)
        local _esc_cap="esc_$1" && shift
        [ ! -v "$_esc_cap" ] || _esc_val+=${!_esc_cap}
        ;;
    esac
  done

  if [ "${_esc_var-}" ]; then
    printf -v "$_esc_var" '%s' "$_esc_val"
  else
    printf '%s' "$_esc_val" >&2
  fi
}

# Invokes a utility function.
# Arguments:
#   v - same behavior as `printf -v`
#   * - args passed to the utility function.
util() {
  local args=() _util_var usage="[-v VAR] UTIL [ARGS...]"
  while (($#)); do
    case $1 in
      -v)
        [ "${2-}" ] || failr "value of var missing" --usage "$usage" -- "$@"
        _util_var=$2 && shift 2
        ;;
      *)
        args+=("$1") && shift
        ;;
    esac
  done
  set -- "${args[@]}"
  [ $# = 0 ] && failr "command missing" --usage "$usage" -- "$@"

  # utilities
  local util_text
  # bashsupport disable=BP2001
  case $1 in
    center)
      args=() usage="${usage%UTIL*}$1 [-w|--width WIDTH] TEXT"
      shift
      local util_center_width
      while (($#)); do
        case $1 in
          -w | --width)
            [ "${2-}" ] || failr "value of width missing" --usage "$usage" -- "$@"
            util_center_width=$2 && shift 2
            ;;
          *)
            args+=("$1") && shift
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
            _icon_center=true && shift
            ;;
          *)
            args+=("$1") && shift
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

    # prints the optional icon and text
    print | reprint)
      args=() usage="${usage%UTIL*}$1 [-i|--icon ICON] [FORMAT [ARGS...]]"
      if [ "$1" = reprint ]; then
        shift
        if [ "${1-}" = --skip-icon ]; then
          shift
          esc cuu1 hpa_margin eel
        else
          esc cuu1 ewl
        fi
      else
        shift
      fi
      local print_icon=${esc_hpa_margin-$MARGIN} icon_last=false
      while (($#)); do
        case $1 in
          -i | --icon)
            [ "${2-}" ] || usage
            icon_last=true
            util -v print_icon icon --center "$2" && shift 2
            ;;
          *)
            icon_last=false
            args+=("$1") && shift
            ;;
        esac
      done
      set -- "${args[@]}"

      # shellcheck disable=SC2059
      local text='' && [ $# -eq 0 ] || printf -v text "$@"
      text=${text//$LF/$LF$MARGIN}
      [ "${icon_last-}" = true ] || util_text=$print_icon$text
      [ ! "${icon_last-}" = true ] || util_text=$text$print_icon
      ;;

    prefix)
      args=() usage="${usage%UTIL*}$1 [--config CONFIG] [FORMAT [ARGS...]]"
      local prefix_colors=(black cyan blue green yellow magenta red) config
      shift
      while (($#)); do
        case $1 in
          --config)
            [ "${2-}" ] || failr "value for config missing" --usage "$usage" -- "$@"
            config=$2 && shift 2
            ;;
          *)
            args+=("$1") && shift
            ;;
        esac
      done
      set -- "${args[@]}"

      local prefix='' name color bg_color props char state
      while IFS=' ' read -r -d: -a props || props=''; do
        [ "${#prefix_colors[@]}" -gt 0 ] || break
        name=${prefix_colors[0]} char=$BANR_CHAR state=1 && prefix_colors=("${prefix_colors[@]:1}")
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

        color="esc_bright_$name"
        bg_color=''
        if [ "${state-}" ]; then
          [ ! "${state:0:1}" = 0 ] || color="esc_$name"
          [ ! "${state:1:1}" = 0 ] || bg_color="esc_bg_$name"
          [ ! "${state:1:1}" = 1 ] || bg_color="esc_bg_bright_$name"
        fi

        [ ! -v "${color-}" ] || prefix+=${!color}
        [ ! -v "${bg_color-}" ] || prefix+=${!bg_color}
        prefix+=$char${esc_reset-}
        prefix+=${esc_reset-}
      done <<<"${config-} :"

      # shellcheck disable=SC2034,SC2059
      local parts=("$prefix") && [ $# -eq 0 ] || printf -v parts[1] "$@"
      printf -v util_text %s "${parts[*]}"
      ;;

    # colored banner words
    words)
      shift
      local prefix_colors=("${esc_cyan-}" "${esc_dim-}${esc_cyan-}" "${esc_magenta-}")
      case ${1-} in
        --bright)
          prefix_colors=("${esc_bright_cyan-}" "${esc_cyan-}" "${esc_bright_magenta-}") && shift
          ;;
        --dimmed)
          prefix_colors=("${esc_cyan-}" "${esc_dim-}${esc_cyan-}" "${esc_magenta-}") && shift
          ;;
      esac
      # shellcheck disable=SC2059
      local _words_text && [ $# -eq 0 ] || printf -v _words_text "$@"
      # shellcheck disable=SC2015
      local -a _words=() && [ ! "${_words_text-}" ] || IFS=' ' read -r -a _words <<<"$_words_text"
      local -a _colored=()
      local i
      for i in "${!_words[@]}"; do
        # color all but first words bright magenta
        if [ "$i" -gt 0 ]; then
          _colored+=("${prefix_colors[2]}${_words[$i]^^}${esc_reset-}")
          continue
        fi

        # split first word camelCase; first word -> bright cyan; rest -> cyan
        # shellcheck disable=SC2001
        local -a _words0 && read -r -a _words0 <<<"$(echo "${_words[$i]}" | sed -e 's/\([A-Z]\)/ \1/g')"
        if [ ${#_words0[@]} -gt 0 ]; then
          _colored+=("${prefix_colors[0]}${_words0[0]^^}${esc_reset-}")
          if [ ${#_words0[@]} -gt 1 ]; then
            local _word=${_words0[*]:1}
            _word=${_word// /}
            _colored+=("${prefix_colors[1]}${_word^^}${esc_reset-}")
          fi
        fi
      done
      printf -v util_text %s "${_colored[*]}"
      ;;

    *)
      failr "unknown command" --usage "$usage" -- "$@"
      ;;
  esac

  if [ "${_util_var-}" ]; then
    printf -v "$_util_var" '%s' "$util_text"
  else
    printf '%s\n' "$util_text"
  fi
}

# Invokes a spinner function.
# Arguments:
#   * - args passed to the spinner function.
spinner() {
  [ "${tty_connected-}" ] || return 0
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
      local -a frames=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
      local _i
      for _i in "${!frames[@]}"; do
        util -v "frames[$_i]" center "${frames[$_i]}"
      done
      while true; do
        for _i in "${!frames[@]}"; do
          printf '%s' "${esc_save-}" "${esc_hpa0-}" "${esc_cuu1-}" "${esc_bright_yellow-}" "${frames[$_i]}" "${esc_reset-}" "${esc_load-}" >&2
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
# Globals:
#   BANR_CHAR - the default char to use
# Arguments:
#   --indent - Either the amount of whitespaces or the string itself to prepend the banner with (default: 1)
#   --static - If specified, not animation will take place; optionally can be set to a pattern that controls the design.
#              Format: colon (:) separated list of space separated key-value pairs, e.g. `char=A : char=B state=1` specifies
#                      the first banner char as an `A`, the second as a `B` with bright colors and the remaining chars as default.
#   --bright - Whether bright colors should be applied (default: set)
#   --dimmed - Whether dimmed colors should be applied.
#   --opacity - The opacity of the banner. Valid values are `high`, `medium`, or `low`.
#   --skip-intro - If specified, the animation will not play the intro.
#   --skip-outro - If specified, the animation will not play the outro.
#   + - Positional arguments are interpreted as the actual text.
banr() {
  local -a args=()
  local indent=3 config type=bright
  local intro=true intro_char=$'\u00A0' intro_modifier='' intro_state='10'
  local outro=true outro_char=$BANR_CHAR outro_modifier='' outro_state='1'
  while (($#)); do
    case $1 in
      --indent=*)
        indent=${1#*=} && shift
        ;;
      --static=*)
        config=${1#*=} && shift
        ;;
      --static)
        config=" " && shift
        ;;
      --bright)
        type=bright && shift
        intro_state="1${intro_state:1:1}"
        outro_state="1${outro_state:1:1}"
        ;;
      --dimmed)
        type=dimmed && shift
        intro_state="0${intro_state:1:1}"
        outro_state="0${outro_state:1:1}"
        ;;
      --opacity=high)
        outro_char=█ && intro_modifier=${esc_default-}${esc_dim-} && shift
        ;;
      --opacity=medium)
        outro_char=▒ && intro_modifier=${esc_default-}${esc_dim-} && shift
        ;;
      --opacity=low | --opacity=*)
        outro_char=░ && intro_modifier=${esc_default-}${esc_dim-} && shift
        ;;
      --skip-intro)
        intro=false
        shift
        ;;
      --skip-outro)
        outro=false
        shift
        ;;
      --)
        shift
        args+=("$@")
        break
        ;;
      *)
        args+=("$1")
        shift
        ;;
    esac
  done

  set -- "${args[@]}"
  printf '\n'

  [[ ! ${indent} =~ [0-9]+ ]] || printf -v indent '%*.s' "$indent" ''

  local raw_prefix && tty_connected='' util -v raw_prefix prefix && raw_prefix=${raw_prefix//[^$BANR_CHAR]/}

  # shellcheck disable=SC2015
  local text && [ "$#" -eq 0 ] || util -v text words ${type+"--${type-}"} '%s' ${@+"${*}"}
  if [ "${config:=}" ] || [ ! "${tty_connected-}" ]; then
    [ "${config// /}" ] || [ ! "${outro_char-}" ] || config="${raw_prefix//?/"c=$outro_char s=$outro_state:" }"
    local _banner && util -v _banner prefix ${config+--config "$config"} ${text+"$text"}
    printf '%s%s\n\n' "$indent" "$_banner"
    return
  fi

  # shellcheck disable=SC2206
  local intro_frames=(${raw_prefix//?/"$intro_char" }) outro_frames=(${raw_prefix//?/"$outro_char" })

  [ ! "${intro-}" = true ] || intro_frames+=(▁ ▂ ▃ ▄ ▅ ▆ ▇ █ █ █ █ ▉ ▊ ▋ ▌ ▍ ▎ ▏ "${intro_char[@]}")
  [ ! "${outro-}" = true ] || outro_frames=(▏ ▎ ▍ ▌ ▋ ▊ ▉ "${outro_frames[@]}")

  intro_frames=("${intro_frames[@]/#/c=$intro_modifier}")
  outro_frames=("${outro_frames[@]/#/c=$outro_modifier}")

  local i frames=("${intro_frames[@]/%/ s=$intro_state}" "${outro_frames[@]/%/ s=$outro_state}")
  for ((i = 0; i < ${#frames[@]}; i++)); do
    local props=("${frames[@]:i:${#raw_prefix}}")
    [ "${#props[@]}" -eq 7 ] || break
    local _banr_words=''
    [ ! "$i" = 0 ] || util -v _banr_words words ${type+"--${type-}"} ' %s' "$@"
    printf '%s' "$indent"
    util prefix --config "${props[*]/%/ :}" "$_banr_words"
    esc cuu1
    sleep 0.0125
  done
  sleep 1.2
  printf '\n\n'
}

# Banner configuration suited for titles and headlines.
# Arguments: see `banr`
# bashsupport disable=BP5005
HEADR() {
  banr --bright --opacity=high "$@"
}

# Banner configuration suited for headlines and sub headlines.
# Arguments: see `banr`
headr() {
  banr --bright --skip-intro "$@"
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
      printf '\n   logr %s\n\n   Usage: logr %s%s' "$LOGR_VERSION" "$usage" '

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
      esc cursor_hide
      ;;
    _cleanup)
      shift
      esc cursor_show
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
      util print --icon "$1" "${@:2}"
      ;;
    error | fail)
      util print --icon "$1" "${@:2}" >&2
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
      local url="$1" text=${2-}
      # shellcheck disable=SC1003
      if [ "${tty_connected-}" ]; then
        util print --icon link '\e]8;;%s\e\\%s\e]8;;\e\\' "$url" "${text:-$url}"
      else
        if [ "${text-}" ]; then
          util print --icon link '[%s](%s)' "$url" "$text"
        else
          util print --icon link '%s' "$url"
        fi
      fi
      ;;
    file)
      usage="${usage%COMMAND*}$1 [-l|--line LINE [-c|--column COLUMN]] PATH [TEXT]"
      shift
      local args=() line column
      while (($#)); do
        case $1 in
          -l | --line)
            [ "${2-}" ] || failr "value of line missing" --usage "$usage" -- "$@"
            line=$2 && shift 2
            ;;
          -c | --column)
            [ "${2-}" ] || failr "value of column missing" --usage "$usage" -- "$@"
            column=$2 && shift 2
            ;;
          *)
            args+=("$1") && shift
            ;;
        esac
      done
      set -- "${args[@]}"
      [ $# -ge 1 ] || failr "path missing" --usage "$usage" -- "$@"
      local path=$1
      local text=${2-}
      [[ $path =~ ^/ ]] || path="$PWD/$path"
      if [ "${line-}" ]; then
        # line suffix at needed by IntelliJ
        if [[ ${__CFBundleIdentifier-} == "com.jetbrains"* ]]; then
          path+=":$line"
        else
          # line suffix as specified by iTerm 2
          path+="#$line"
        fi
        [ ! "${column-}" ] || path+=":$column"
      fi
      local url="file://$path"
      if [ "${tty_connected-}" ]; then
        logr link "$url" "${text:-$url}"
      else
        logr link "$url" ${text+"$text"}
      fi
      ;;
    running)
      util print --icon "$1" "${@:2}"
      ;;
    task)
      usage="${usage%COMMAND*}$1 [FORMAT [ARGS...]] [-- COMMAND [ARGS...]]"
      shift
      local format=()
      while (($#)); do
        case $1 in
          --)
            shift && break
            ;;
          *)
            format+=("$1") && shift
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
        util print --icon task "$logr_task"
        return 0
      fi

      local logr_tasks && util -v logr_tasks fit_concat nest "$logr_parent_tasks" "$logr_task"

      local task_file && task_file=${TMPDIR:-/tmp}/logr.$$.task
      local log_file && log_file=${TMPDIR:-/tmp}/logr.$$.log

      local task_exit_status=0
      if [ ! "$logr_parent_tasks" ]; then
        [ ! -f "$task_file" ] || rm -- "$task_file"
        [ ! -f "$log_file" ] || rm -- "$log_file"
        util print "$logr_tasks"
        spinner start
        # run command line; redirect stdout+stderr to log_file; provide FD3 and FD4 as means to still print
        (logr_parent_tasks=$logr_tasks "${cmdline[@]}" 3>&1 1>"$log_file" 4>&2 2>"$log_file") || task_exit_status=$?
      else
        util reprint --skip-icon "$logr_tasks" 1>&3 2>&4
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
          util reprint --icon error "$(cat "$task_file")"
          sed \
            -e 's/[\[(][(0-9;]*[a-zA-Z]//g;' \
            -e 's/^/'"$MARGIN${esc_red-}"'/;' \
            -e 's/$/'"${esc_reset-}"'/;' \
            "$log_file"
          exit $task_exit_status
        fi

        # success
        # erase what has been printed on same line by printing task_line again
        util reprint --icon success "$logr_tasks"
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
      printf '\n   prompt4 %s\n\n   Usage: prompt4 %s%s' "$LOGR_VERSION" "$usage" '

   Type:
     Yn    "Do you want to continue?"
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

      local formatted_question
      util -v formatted_question print '%s%s %s %s' "${esc_bold-}" "${_yn_question%%$LF}" "[Y/n]" "${esc_stout_end-}"
      printf '%s' "$formatted_question"
      esc cursor_show scroll_up cuu1
#      [ "${tty_connected-}" ] || printf '%s' "$MARGIN"
#      [ ! "${tty_connected-}" ] || esc load cuu1

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

      local _prompt4_format="${esc_cursor_hide-}${esc_dim-}%s${esc_reset-}${esc_hpa0-}"
      # shellcheck disable=SC2059,SC2128
      case $_yn_answer in
        n* | **)
          util print "$_prompt4_format" no --icon error
          exit 1
          ;;
        *)
          util print "$_prompt4_format" yes --icon success
          printf '\n'
          sleep .4
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
  local arg_columns=40 && [ ! "${COLUMNS-}" ] || arg_columns=$((COLUMNS / 2))
  local cyan && esc -v cyan bright_cyan
  local reset && esc -v reset reset
  local debug && debug="$cyan%s$reset"
  local quote && printf -v quote "$debug%%s$debug" '`' '`'
  local quote_escape && printf -v quote_escape "$debug%%q$debug" '`' '`'
  local out_args='' out_args_len=0 out_argc=0 out_location='?'

  # shellcheck disable=SC2059
  [ $# -eq 0 ] || {
    printf -v out_args "$quote_escape " "$@"
    printf -v out_args_len '`%q` ' "$@" && out_args_len="${#out_args_len}"
  }

  # shellcheck disable=SC2059
  printf -v out_argc "$debug" "$#"
  local out_argc_pad=' ' && [ $# -le 9 ] || out_argc_pad=''

  [ ! "${BASH_SOURCE[1]-}" ] || out_location=$(logr file ${BASH_LINENO[0]+--line "${BASH_LINENO[0]}"} "${BASH_SOURCE[1]}")
  local missing=$((arg_columns - out_args_len - 4))
  [ "$missing" -gt 0 ] || missing=1
  printf '%s%s %s%*s %s\n' "$out_argc_pad" "$out_argc" "$out_args" "$missing" '' "$out_location"
}

# Initializes environment
main() {

  TMPDIR=${TMPDIR:-/tmp}
  TMPDIR=${TMPDIR%/}

  # bashsupport disable=BP5006
  declare -g -r \
    LOGR_VERSION=SNAPSHOT \
    BANR_CHAR='▔' \
    MARGIN='   ' \
    LF=$'\n'

  esc --init

  declare -A -g logr_icons=(
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
    ['fail']='ϟ'
  )

  declare -g logr_parent_tasks=''

  local r=${esc_reset-}
  declare -A -g -r logr_templates=(
    ['new']="${esc_yellow-}%s$r"
    ['link']="${esc_blue-}%s$r"
    ['file']="${esc_blue-}%s$r"
    ['task']="${esc_blue-}%s$r"
    ['nest']="${esc_yellow-}%s$r"
    ['running']="${esc_yellow-}%s$r"
    ['success']="${esc_green-}%s$r"
    ['info']="${esc_white-}%s$r"
    ['warn']="${esc_bright_yellow-}%s$r"
    ['error']="${esc_red-}%s$r"
    ['fail']="${esc_bold-}${esc_red-}%s$r"
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

  set +e

  [ "${RECORDING-}" ] || {
    echo
    logr error '%s\n' "To use logr you need to source it at the top of your script."
    logr info '%s\n%s\n' 'If logr is on your $PATH type:' 'source logr.sh'
    logr info '%s\n%s\n' 'To source logr from the same directory as your script add:' \
      'source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)/logr.sh"'
    logr info '%s\n%s\n' 'To source logr relative to your script add:' \
      'source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)/RELATIVE_PATH/logr.sh"'
    logr info '%s\n%s\n' 'And for the more adventurous:' \
      'source <(curl -LfsS https://git.io/logr.sh)'

    prompt4 Yn "Would you like to explore the provides functions beforehand?"
  }

  # bashsupport disable=BP5005
  # Starts a showcase group and prints the specified text as a demo headline.
  DEMO() {
    [ ! "${RECORDING-}" ] || [ "${!#}" = 📸 ] || exit 0
    [ "${BASH_SUBSHELL-}" -gt 1 ] || set -- --opacity=high "$@"
    [ ! "${BASH_SUBSHELL-}" = 3 ] || set -- --dimmed --static "$@"
    banr "${@//📸/}" && sleep 0.5
  }
  # Executes a single showcase.
  _() {
    printf ' $ ' && esc cursor_show
    local i j s && s=$(printf '%q ' "$@")
    [ ! "${1-}" = "eval" ] || s=${2-} # type only payload on eval command
    for ((i = 0, j = 0; i < ${#s}; i = i + j, j = 10 + (RANDOM % 5))); do
      printf '%s' "${s:i:j}" && sleep .01
    done
    esc cursor_hide reset && sleep .5
    if [ "${1-}" = "banr" ]; then
      ("$1" --indent=10 "${@:1}")
    else
      printf '%s\n' "${esc_reset-} " && ("$@")
      printf '\n'
    fi
  }
  # bashsupport disable=BP5005
  # Ends a showcase group and prints all arguments.
  END() {
    sleep 2
  }

  (
    DEMO logr bash logger 📸
    _ logr new "text"
    _ logr item "text"
    _ logr list "text-1" "text-2" "text-3"
    _ logr link "https://github.com/bkahlert/logr"
    _ logr link "https://example.com" "link-text"
    _ logr file --line 300 --column 10 "logr.sh"
    _ logr file --line 300 --column 10 "logr.sh" "link-text"
    _ logr success "text"
    _ logr info "text"
    _ logr warn "text"
    _ logr error "text"
    _ logr fail "text"

    _ logr task "text"
    _ logr running "text"
    _ logr task "text" -- sleep 0.5
    _ logr task -- bash -c '
echo foo && sleep 0.5
echo bar >&2 && sleep 0.5
echo baz >&2 && sleep 0.5
exit 2'

    # vanilla recursion
    foo() {
      logr info "foo args: $*"
      [ "$1" -eq 0 ] || foo $(($1 - 1)) "$2"
      sleep 0.5
      [ ! "$1" = "$2" ] || exit 1
    }
    _ logr task -- foo 3 -
    _ logr task -- foo 3 2

    # logr task recursion
    bar() {
      logr info "bar args: $*"
      [ "$1" -eq 0 ] || logr task -- bar $(($1 - 1)) "$2"
      sleep 0.5
      [ ! "$1" = "$2" ] || exit 1
    }
    _ logr task -- bar 3 -
    _ logr task -- bar 3 2

    # provoking line overflow
    supercalifragilisticexpialidocious() {
      local long="${FUNCNAME[0]}"
      sleep 0.5
      logr task -- logr task -- echo "$long $long $long $long $long"
      sleep 0.5
      logr task -- logr task -- echo "$long $long $long $long $long"
      sleep 0.5
    }
    _ logr task "running supercalifragilisticexpialidocious without breaking output" -- supercalifragilisticexpialidocious
    END
  )

  (
    DEMO prompt4 simple user feedback 📸
    _ eval 'echo y | prompt4 Yn'
    _ eval 'echo y | prompt4 Yn "Single line"'
    _ eval 'echo y | prompt4 Yn "%s\n" "Multi-" "line"'
    _ eval 'echo y | prompt4 Yn "%s\n" "Multi-" "line" -'
    _ eval 'echo n | prompt4 Yn'
    _ eval 'echo n | prompt4 Yn "Single line"'
    _ eval 'echo n | prompt4 Yn "%s\n" "Multi-" "line"'
    _ eval 'echo n | prompt4 Yn "%s\n" "Multi-" "line" -'
    END
  )

  (
    DEMO failr error message util 📸
    _ failr --warn
    _ failr --

    # pretends to need argument
    foo() {
      [ "$1" = baz ] || failr "baz expected" --usage "baz" -- "$*"
    }
    _ foo bar
    END
  )

  (
    DEMO utilities 📸

    (
      DEMO esc 📸
      for color in BLACK RED GREEN YELLOW BLUE MAGENTA CYAN WHITE; do
        local esc_bright_color="esc_bright_${color,,}"
        local esc_color="esc_${color,,}"
        if [ -v "${esc_bright_color-}" ]; then
          esc_bright_color="${!esc_bright_color}"
        else
          esc_bright_color=""
        fi
        if [ -v "${esc_color-}" ]; then
          esc_color="${!esc_color}"
        else
          esc_color=""
        fi
        printf "%8s %sNORMAL%sDIMMED%s %sBRIGHT%sDIMMED%s\n" "${color^^}" \
          "${esc_color-}" "${esc_dim-}${esc_color-}" "${esc_reset-}" \
          "${esc_bright_color-}" "${esc_dim-}${esc_bright_color-}" "${esc_reset-}"
      done
      END
    )

    (
      DEMO banr 📸
      _ banr --static
      _ banr --static foo
      _ banr --static fooBar
      _ banr --static fooBar baz
      _ banr --static='c=■:c=▪:c=■:c=▪:c=■:c=▪:c=■'
      _ banr --static --bright fooBar baz
      _ banr --static --dimmed fooBar baz
      _ banr --static --opacity=low
      _ banr --static --opacity=medium
      _ banr --static --opacity=high

      _ banr
      _ banr --skip-intro
      _ banr --skip-outro
      _ banr --skip-intro --skip-outro
      _ banr --opacity=medium
      _ banr --opacity=medium --skip-intro
      _ banr --opacity=medium --skip-outro
      _ banr --opacity=medium --skip-intro --skip-outro
      END
    )

    (
      DEMO util 📸

      (
        DEMO util inline 📸
        _ util inline ' foo'
        _ util inline ' %s\n' 'foo' 'bar'
        _ util inline ' %s\n' 'foo' 'bar' 'baz'
        END
      )

      (
        DEMO util center 📸
        # helper
        wrap() {
          local delim="${esc_dim-}|${esc_reset-}"
          printf ' %s%s%s\n' "$delim" "$("$@")" "$delim"
        }
        _ wrap util center ""
        _ wrap util center "✘"
        _ wrap util center -w 2 '👐'
        _ wrap util center "12"
        _ wrap util center "123"
        _ wrap util center "1234"
        END
      )

      (
        DEMO util icon 📸
        _ eval 'printf "%s" "$MARGIN" && util icon _unknown_'
        _ eval 'printf "%s" "$MARGIN" && util icon success'
        _ eval 'printf "%s" "$MARGIN" && util icon --center success'

        local icons=()
        tabs 12,+4,+8,+4,+8,+4,+8,+4 2>/dev/null
        for icon in "${!logr_icons[@]}"; do
          icons+=("${esc_dim-}$icon${esc_reset-}" "$(util icon "$icon")")
        done
        printf "$MARGIN%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" "${icons[@]}"
        END
      )

      (
        DEMO util print reprint 📸
        _ util print 'text'
        _ util print --icon _unknown_ 'text'
        _ util print --icon success 'text'
        _ eval 'util print "old text" && sleep 0.3 && util reprint "new text"'
        _ eval 'util print --icon _unknown_ "old text" && sleep 0.3 && util reprint --icon success "new text"'
        _ eval 'util print --icon success "old text" && sleep 0.3 && util reprint --icon success "new text"'
        END
      )
    )

    (
      DEMO tracr 📸
      _ tracr
      _ tracr foo
      _ tracr foo bar
      _ tracr -foo --bar -- ---baz
      END
    )
  )

  exit 0
}

main "$@"
