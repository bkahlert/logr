#!/usr/bin/env bash

set -uo pipefail

# query specified terminal: infocmp $1 | sed -e 's/,/\n/' -e 's/\t/ /'

source <(curl -LfsS https://git.io/init.rc)
banr --opacity=invalid

dim_normal_bright(){
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
}

# 16 colors
for clbg in {40..47} {100..107} 49 ; do
	#Foreground
	for clfg in {30..37} {90..97} 39 ; do
		#Formatting
		for attr in 0 1 2 4 5 7 ; do
			#Print the result
			echo -en "\e[${attr};${clbg};${clfg}m ^[${attr};${clbg};${clfg}m \e[0m"
		done
		echo #Newline
	done
done

# 256 colors
for fgbg in 38 48 ; do # Foreground / Background
    for color in {0..255} ; do # Colors
        # Display the color
        printf "\e[${fgbg};5;%sm  %3s  \e[0m" $color $color
        # Display 6 colors per lines
        if [ $((($color + 1) % 6)) == 4 ] ; then
            echo # New line
        fi
    done
    echo # New line
done



# Links
# ~~[Helpful Ncurses Programs](https://www.askapache.com/linux/zen-terminal-escape-codes/#Helpful_Ncurses_Programs)~~
# ~~[Standard Capabilities](https://www.askapache.com/linux/zen-terminal-escape-codes/#Standard_Capabilities)~~
# [Bash tips: Colors and formatting (ANSI/VT100 Control sequences)](https://misc.flogisoft.com/bash/tip_colors_and_formatting)


# Shows all capabilities and their sequences
# infocmp -1Lq|grep -v "$TERM|#"|tr -d '  '

# Prints the specified amount of times the specified text.
# Arguments:
#   1 - times
#   2 - optional text (default: space)
# Returns:
#   0 - success
#   1 - invalid times parameter
repeat() {
  local times=${1?times missing} text=${2- } _repeat_result
  [ ! "${times:0:1}" = - ] || return 1
  printf -v _repeat_result '%*s' "$times" ''
  printf '%s\n' "${_repeat_result// /$text}"
}

# Prints a guide line of which the line is a long a needed to pad
# the passed argument to a fixed length.
guide() {
  local pad=118
  # shellcheck disable=SC2155
  # bashsupport disable=BP2001
  [ "${_guide-}" ] || declare -g -r _guide=$(repeat "$pad" '.')
  printf '%s\n' "${_guide:0:$((pad - ${#1}))}"
}

# Prints the given boolean capability
boolean_diag() {
  local variable=${1?capname missing} capname=${2?capname missing} termcap=${3?termcap missing} description=${4?description missing} result
  if tput "$capname"; then
    result=true
    description="$(tput setaf 2)$description$(tput sgr0)"
  else
    [ "${HIDE_UNSUPPORTED:-false}" = false ] || return 0
    result=''
  fi
  printf '%s%s\t%s\t%s\t%s\t%s\n' "$result" "$(guide "$result")" "$variable" "$capname" "$termcap" "$description"
}

# Prints the given numeric capability
numeric_diag() {
  local variable=${1?capname missing} capname=${2?capname missing} termcap=${3?termcap missing} description=${4?description missing} result
  if result=$(tput "$capname"); then
    description="$(tput setaf 2)$description$(tput sgr0)"
  else
    [ "${HIDE_UNSUPPORTED:-}" = false ] || return 0
    result=""
  fi
  printf '%s%s\t%s\t%s\t%s\t%s\n' "$result" "$(guide "$result")" "$variable" "$capname" "$termcap" "$description"
}

# Prints the given string capability
string_diag() {
  local variable=${1?capname missing} capname=${2?capname missing} termcap=${3?termcap missing} description=${4?description missing} result
  local -a args=("${@:5}")
  if result=$(tput "$capname" "${args[@]}"); then
    #    result=$(cat -v <<<"$result")
    #    result=$(hexdump -v <<<"$result")
    result=$(printf '%q' "$result")
    description="$(tput setaf 2)$description$(tput sgr0)""${args+ (${args[*]})}"
  else
    [ "${HIDE_UNSUPPORTED:-false}" = false ] || return 0
    result=""
  fi
  printf '%s%s\t%s\t%s\t%s\t%s\n' "$result" "$(guide "$result")" "$variable" "$capname" "$termcap" "$description"
}

# Prints the capabilities information about the current terminal
# bashsupport disable=SpellCheckingInspection
main() {
  #  command printf '6n'
  #  command printf '[6n'
  #  sleep 1
  #  command printf '\E[6n'
  #  sleep 1
  #  command printf '\E[3h'
  #  command printf '\E[32'
  #sleep 10
  #  printf '%q' "$(tput setaf 2)xxx"
  #echo "X"

  tabs 120,+30,+10,+11
  # bashsupport disable=BP5006
  export HIDE_UNSUPPORTED=true

  printf '\n%s\n' "BOOLEAN CAPABILITIES"
  printf '%s\t%s\t%s\t%s\t%s\n' "RESULT" "VARIABLE" "CAPNAME" "TC""AP CODE" "DESCRIPTION"

  boolean_diag 'auto_left_margin' 'bw' 'bw' "cub1 wraps from column 0 to last column"
  boolean_diag 'auto_right_margin' 'am' 'am' "terminal has automatic margins"
  boolean_diag 'back_color_erase' 'bce' 'ut' "screen erased with background color"
  boolean_diag 'can_change' 'ccc' 'cc' "terminal can re- define existing colors"
  boolean_diag 'ce''ol_standout_glitch' 'xhp' 'xs' "standout not erased by overwriting (hp)"
  boolean_diag 'col_ad''dr_glitch' 'xh''pa' 'YA' "only positive motion for hpa/mh""pa caps"
  boolean_diag 'cpi_changes_res' 'cp''ix' 'YF' "changing character pitch changes resolution"
  boolean_diag 'cr_cancels_micro_mode' 'cr''xm' 'YB' "using cr turns off micro mode"
  boolean_diag 'dest_tabs_magic_sm''so' 'xt' 'xt' "tabs destructive, magic so char (t1061)"
  boolean_diag 'eat_newline_glitch' 'xe''nl' 'xn' "newline ignored after 80 cols (concept)"
  boolean_diag 'erase_over''strike' 'eo' 'eo' "can erase over""strikes with a blank"
  boolean_diag 'generic_type' 'gn' 'gn' "generic line type"
  boolean_diag 'hard_copy' 'hc' 'hc' "hard""copy terminal"
  boolean_diag 'hard_cursor' 'ch''ts' 'HC' "cursor is hard to see"
  boolean_diag 'has_meta_key' 'km' 'km' "Has a meta key (i.e., sets 8th-bit)"
  boolean_diag 'has_print_wheel' 'daisy' 'YC' "printer needs operator to change character set"
  boolean_diag 'has_status_line' 'hs' 'hs' "has extra status line"
  boolean_diag 'hue_lightness_saturation' 'hls' 'hl' "terminal uses only HLS color notation (Tek""tro""nix)"
  boolean_diag 'insert_null_glitch' 'in' 'in' "insert mode distinguishes nulls"
  boolean_diag 'lpi_changes_res' 'lp''ix' 'YG' "changing line pitch changes resolution"
  boolean_diag 'memory_above' 'da' 'da' "display may be retained above the screen"
  boolean_diag 'memory_below' 'db' 'db' "display may be retained below the screen"
  boolean_diag 'move_insert_mode' 'mir' 'mi' "safe to move while in insert mode"
  boolean_diag 'move_standout_mode' 'msgr' 'ms' "safe to move while in standout mode"
  boolean_diag 'needs_xon_xo''ff' 'nx''on' 'nx' "padding will not work, xon/xo""ff required"
  boolean_diag 'no_esc_ct''lc' 'xsb' 'xb' "beehive (f1=escape, f2=ctrl C)"
  boolean_diag 'no_pad_char' 'npc' 'NP' "pad character does not exist"
  boolean_diag 'non_dest_scroll_region' 'nd''scr' 'ND' "scrolling region is non-destructive"
  boolean_diag 'over_strike' 'os' 'os' "terminal can over""strike"
  boolean_diag 'pr''tr_silent' 'mc5i' '5i' "printer will not echo on screen"
  boolean_diag 'row_ad''dr_glitch' 'xv''pa' 'YD' "only positive motion for vpa/mv''pa caps"
  boolean_diag 'semi_auto_right_margin' 'sam' 'YE' "printing in last column causes cr"
  boolean_diag 'status_line_esc_ok' 'es''lok' 'es' "escape can be used on the status line"
  boolean_diag 'tilde_glitch' 'hz' 'hz' "cannot print ~'s (Hazel""tine)"
  boolean_diag 'transparent_underline' 'ul' 'ul' "underline character over""strikes"
  boolean_diag 'xon_xo''ff' 'xon' 'xo' "terminal uses xon/xo""ff handshaking"

  printf '\n%s\n' "NUMERIC CAPABILITIES"
  printf '%s\t%s\t%s\t%s\t%s\n' "RESULT" "VARIABLE" "CAPNAME" "TC""AP CODE" "DESCRIPTION"
  numeric_diag 'columns' 'cols' 'co' "number of columns in a line"
  numeric_diag 'init_tabs' 'it' 'it' "tabs initially every # spaces"
  numeric_diag 'label_height' 'lh' 'lh' "rows in each label"
  numeric_diag 'label_width' 'lw' 'lw' "columns in each label"
  numeric_diag 'lines' 'lines' 'li' "number of lines on screen or page"
  numeric_diag 'lines_of_memory' 'lm' 'lm' "lines of memory if > line. 0 means varies"
  numeric_diag 'magic_cookie_glitch' 'xmc' 'sg' "number of blank characters left by sm""so or rm""so"
  numeric_diag 'max_attributes' 'ma' 'ma' "maximum combined attributes terminal can handle"
  numeric_diag 'max_colors' 'colors' 'Co' "maximum number of colors on screen"
  numeric_diag 'max_pairs' 'pairs' 'pa' "maximum number of color-pairs on the screen"
  numeric_diag 'maximum_windows' 'wn''um' 'MW' "maximum number of definable windows"
  numeric_diag 'no_color_video' 'ncv' 'NC' "video attributes that cannot be used with colors"
  numeric_diag 'num_labels' 'nl''ab' 'Nl' "number of labels on screen"
  numeric_diag 'padding_baud_rate' 'pb' 'pb' "lowest baud rate where padding needed"
  numeric_diag 'virtual_terminal' 'vt' 'vt' "virtual terminal number (CB/unix)"
  numeric_diag 'width_status_line' 'wsl' 'ws' "number of columns in status line"
  numeric_diag 'bit_image_entwining' 'bit''win' 'Yo' "number of passes for each bit-image row"
  numeric_diag 'bit_image_type' 'bit''ype' 'Yp' "type of bit-image device"
  numeric_diag 'buffer_capacity' 'buf''sz' 'Ya' "numbers of bytes buffered before printing"
  numeric_diag 'buttons' 'bt''ns' 'BT' "number of buttons on mouse"
  numeric_diag 'dot_ho''rz_spacing' 'spin''h' 'Yc' "spacing of dots horizontally in dots per inch"
  numeric_diag 'dot_vert_spacing' 'spin''v' 'Yb' "spacing of pins vertically in pins per inch"
  numeric_diag 'max_micro_address' 'ma''ddr' 'Yd' "maximum value in micro_..._address"
  numeric_diag 'max_micro_jump' 'mj''ump' 'Ye' "maximum value in parm_..._micro"
  numeric_diag 'micro_col_size' 'mcs' 'Yf' "character step size when in micro mode"
  numeric_diag 'micro_line_size' 'mls' 'Yg' "line step size when in micro mode"
  numeric_diag 'number_of_pins' 'np''ins' 'Yh' "numbers of pins in print-head"
  numeric_diag 'output_res_char' 'orc' 'Yi' "horizontal resolution in units per line"
  numeric_diag 'output_res_ho''rz_inch' 'or''hi' 'Yk' "horizontal resolution in units per inch"
  numeric_diag 'output_res_line' 'orl' 'Yj' "vertical resolution in units per line"
  numeric_diag 'output_res_vert_inch' 'or''vi' 'Yl' "vertical resolution in units per inch"
  numeric_diag 'print_rate' 'cps' 'Ym' "print rate in characters per second"
  numeric_diag 'wide_char_size' 'wi''dcs' 'Yn' "character step size when in double wide mode"

  printf '\n%s\n' "STRING CAPABILITIES"
  printf '%s\t%s\t%s\t%s\t%s\n' "RESULT" "VARIABLE" "CAPNAME" "TC""AP CODE" "DESCRIPTION"
  string_diag 'acs_chars' 'ac''sc' 'ac' "graphics charset pairs, based on vt100"
  string_diag 'back_tab' 'cbt' 'bt' "back tab (P)"
  string_diag 'bell' 'bel' 'bl' "audible signal (bell) (P)"
  string_diag 'carriage_return' 'cr' 'cr' "carriage return (P*) (P*)"
  string_diag 'change_char_pitch' 'cpi' 'ZA' "Change number of characters per inch to #1"
  string_diag 'change_line_pitch' 'lpi' 'ZB' "Change number of lines per inch to #1"
  string_diag 'change_res_ho''rz' 'chr' 'ZC' "Change horizontal resolution to #1"
  string_diag 'change_res_vert' 'cvr' 'ZD' "Change vertical resolution to #1"
  string_diag 'change_scroll_region' 'csr' 'cs' "change region to line #1 to line #2 (P)"
  string_diag 'char_padding' 'rmp' 'rP' "like ip but when in insert mode"
  string_diag 'clear_all_tabs' 'tbc' 'ct' "clear all tab stops (P)"
  string_diag 'clear_margins' 'mgc' 'MC' "clear right and left soft margins"
  string_diag 'clear_screen' 'clear' 'cl' "clear screen and home cursor (P*)"
  string_diag 'clr_bol' 'el1' 'cb' "clear to beginning of line"
  string_diag 'clr_eol' 'el' 'ce' "clear to end of line (P)"
  string_diag 'clr_eos' 'ed' 'cd' "clear to end of screen (P*)"

  # cursor related caps
  string_diag 'cursor_home' 'home' 'ho' "home cursor (if no cup)"
  string_diag 'column_address' 'hpa' 'ch' "horizontal position #1, absolute (P)"
  string_diag 'row_address' 'vpa' 'cv' "vertical position #1 absolute (P)"
  string_diag 'cursor_address' 'cup' 'cm' "move to row #1 columns #2"
  string_diag 'cursor_mem_address' 'mr''cup' 'CM' "memory relative cursor addressing, move to row #1 columns #2"
  string_diag 'enter_ca_mode' 'sm''cup' 'ti' "string to start programs using cup"
  string_diag 'exit_ca_mode' 'rm''cup' 'te' "strings to end programs using cup"
  boolean_diag 'non_rev_rm''cup' 'nr''rmc' 'NR' "sm""cup does not reverse rm""cup"
  string_diag 'cursor_to_ll' 'll' 'll' "last line, first column (if no cup)"
  string_diag 'cursor_left' 'cub1' 'le' "move left one space"
  string_diag 'cursor_right' 'cuf1' 'nd' "non-destructive space (move right one space)"
  string_diag 'cursor_up' 'cuu1' 'up' "up one line"
  string_diag 'cursor_down' 'cud1' 'do' "down one line"
  string_diag 'parm_left_cursor' 'cub' 'LE' "move #1 characters to the left (P)"
  string_diag 'parm_right_cursor' 'cuf' 'RI' "move #1 characters to the right (P*)"
  string_diag 'parm_up_cursor' 'cuu' 'UP' "up #1 lines (P*)"
  string_diag 'parm_down_cursor' 'cud' 'DO' "down #1 lines (P*)"
  string_diag 'save_cursor' 'sc' 'sc' "save current cursor position (P)"
  string_diag 'restore_cursor' 'rc' 'rc' "restore cursor to position of last save_cursor"
  string_diag 'cursor_invisible' 'civis' 'vi' "make cursor invisible"
  string_diag 'cursor_visible' 'cv''vis' 'vs' "make cursor very visible"
  string_diag 'cursor_normal' 'cn''orm' 've' "make cursor appear normal (undo civis/cv""vis)"

  string_diag 'command_character' 'cm''dch' 'CC' "terminal settable cmd character in prototype !?"
  string_diag 'create_window' 'cw''in' 'CW' "define a window #1 from #2,#3 to #4,#5"
  string_diag 'define_char' 'de''fc' 'ZE' "Define a character #1, #2 dots wide, descender #3"
  string_diag 'delete_character' 'dch1' 'dc' "delete character (P*)"
  string_diag 'delete_line' 'dl1' 'dl' "delete line (P*)"
  string_diag 'dial_phone' 'dial' 'DI' "dial number #1"
  string_diag 'dis_status_line' 'dsl' 'ds' "disable status line"
  string_diag 'display_clock' 'dc''lk' 'DK' "display clock"
  string_diag 'down_half_line' 'hd' 'hd' "half a line down"
  string_diag 'ena_acs' 'en''acs' 'eA' "enable alternate char set"
  string_diag 'enter_alt_charset_mode' 'sm''acs' 'as' "start alternate character set (P)"
  string_diag 'enter_am_mode' 'sm''am' 'SA' "turn on automatic margins"
  string_diag 'enter_blink_mode' 'blink' 'mb' "turn on blinking"
  string_diag 'enter_bold_mode' 'bold' 'md' "turn on bold (extra bright) mode"
  string_diag 'enter_delete_mode' 'sm''dc' 'dm' "enter delete mode"
  string_diag 'enter_dim_mode' 'dim' 'mh' "turn on half-bright mode"
  string_diag 'enter_double''wide_mode' 'sw''idm' 'ZF' "Enter double-wide mode"
  string_diag 'enter_draft_quality' 'sd''rfq' 'ZG' "Enter draft-quality mode"
  string_diag 'enter_insert_mode' 'sm''ir' 'im' "enter insert mode"
  string_diag 'enter_italics_mode' 'si''tm' 'ZH' "Enter italic mode"
  string_diag 'enter_leftward_mode' 'sl''m' 'ZI' "Start leftward carriage motion"
  string_diag 'enter_micro_mode' 'sm''icm' 'ZJ' "Start micro-motion mode"
  string_diag 'enter_near_letter_quality' 'sn''lq' 'ZK' "Enter NLQ mode"
  string_diag 'enter_normal_quality' 'sn''rmq' 'ZL' "Enter normal-quality mode"
  string_diag 'enter_protected_mode' 'pr''ot' 'mp' "turn on protected mode"
  string_diag 'enter_reverse_mode' 'rev' 'mr' "turn on reverse video mode"
  string_diag 'enter_secure_mode' 'in''vis' 'mk' "turn on blank mode (characters invisible)"
  string_diag 'enter_shadow_mode' 'ss''hm' 'ZM' "Enter shadow-print mode"
  string_diag 'enter_standout_mode' 'sm''so' 'so' "begin standout mode"
  string_diag 'enter_subscript_mode' 'ss''ubm' 'ZN' "Enter subscript mode"
  string_diag 'enter_superscript_mode' 'ss''upm' 'ZO' "Enter superscript mode"
  string_diag 'enter_underline_mode' 'sm''ul' 'us' "begin underline mode"
  string_diag 'enter_upward_mode' 'sum' 'ZP' "Start upward carriage motion"
  string_diag 'enter_xon_mode' 'sm''xon' 'SX' "turn on xon/xo""ff handshaking"
  string_diag 'erase_chars' 'ech' 'ec' "erase #1 characters (P)"
  string_diag 'exit_alt_charset_mode' 'rm''acs' 'ae' "end alternate character set (P)"
  string_diag 'exit_am_mode' 'rm''am' 'RA' "turn off automatic margins"
  string_diag 'exit_attribute_mode' 'sgr0' 'me' "turn off all attributes"
  string_diag 'exit_delete_mode' 'rm''dc' 'ed' "end delete mode"
  string_diag 'exit_double''wide_mode' 'rw''idm' 'ZQ' "End double-wide mode"
  string_diag 'exit_insert_mode' 'rm''ir' 'ei' "exit insert mode"
  string_diag 'exit_italics_mode' 'ri''tm' 'ZR' "End italic mode"
  string_diag 'exit_leftward_mode' 'rlm' 'ZS' "End left-motion mode"
  string_diag 'exit_micro_mode' 'rm''icm' 'ZT' "End micro-motion mode"
  string_diag 'exit_shadow_mode' 'rs''hm' 'ZU' "End shadow-print mode"
  string_diag 'exit_standout_mode' 'rm''so' 'se' "exit standout mode"
  string_diag 'exit_subscript_mode' 'rs''ubm' 'ZV' "End subscript mode"
  string_diag 'exit_superscript_mode' 'rs''upm' 'ZW' "End superscript mode"
  string_diag 'exit_underline_mode' 'rmul' 'ue' "exit underline mode"
  string_diag 'exit_upward_mode' 'rum' 'ZX' "End reverse character motion"
  string_diag 'exit_xon_mode' 'rm''xon' 'RX' "turn off xon/xo""ff handshaking"
  string_diag 'fixed_pause' 'pause' 'PA' "pause for 2-3 seconds"
  string_diag 'flash_hook' 'hook' 'fh' "flash switch hook"
  string_diag 'flash_screen' 'flash' 'vb' "visible bell (may not move cursor)"
  string_diag 'form_feed' 'ff' 'ff' "hard''copy terminal page eject (P*)"
  string_diag 'from_status_line' 'fsl' 'fs' "return from status line"
  string_diag 'goto_window' 'wi''ngo' 'WG' "go to window #1"
  string_diag 'hangup' 'hup' 'HU' "hang-up phone"
  string_diag 'init_1string' 'is1' 'i1' "initialization string"
  string_diag 'init_2string' 'is2' 'is' "initialization string"
  string_diag 'init_3string' 'is3' 'i3' "initialization string"
  string_diag 'init_file' 'if' 'if' "name of initialization file"
  string_diag 'init_pr''og' 'ip''rog' 'iP' "path name of program for initialization"
  string_diag 'initialize_color' 'in''itc' 'Ic' "initialize color #1 to (#2,#3,#4)"
  string_diag 'initialize_pair' 'in''itp' 'Ip' "Initialize color pair #1 to fg=(#2,#3,#4), bg=(#5,#6,#7)"
  string_diag 'insert_character' 'ich1' 'ic' "insert character (P)"
  string_diag 'insert_line' 'il1' 'al' "insert line (P*)"
  string_diag 'insert_padding' 'ip' 'ip' "insert padding after inserted character"
  string_diag 'key_a1' 'ka1' 'K1' "upper left of keypad"
  string_diag 'key_a3' 'ka3' 'K3' "upper right of keypad"
  string_diag 'key_b2' 'kb2' 'K2' "center of keypad"
  string_diag 'key_backspace' 'kbs' 'kb' "backspace key"
  string_diag 'key_beg' 'kb''eg' '@1' "begin key"
  string_diag 'key_bt''ab' 'kc''bt' 'kB' "back-tab key"
  string_diag 'key_c1' 'kc1' 'K4' "lower left of keypad"
  string_diag 'key_c3' 'kc3' 'K5' "lower right of keypad"
  string_diag 'key_cancel' 'kc''an' '@2' "cancel key"
  string_diag 'key_ca''tab' 'kt''bc' 'ka' "clear-all-tabs key"
  string_diag 'key_clear' 'kc''lr' 'kC' "clear-screen or erase key"
  string_diag 'key_close' 'kc''lo' '@3' "close key"
  string_diag 'key_command' 'kc''md' '@4' "command key"
  string_diag 'key_copy' 'kc''py' '@5' "copy key"
  string_diag 'key_create' 'kc''rt' '@6' "create key"
  string_diag 'key_ct''ab' 'kc''tab' 'kt' "clear-tab key"
  string_diag 'key_dc' 'kd''ch1' 'kD' "delete-character key"
  string_diag 'key_dl' 'kdl1' 'kL' "delete-line key"
  string_diag 'key_down' 'kc''ud1' 'kd' "down-arrow key"
  string_diag 'key_eic' 'kr''mir' 'kM' "sent by rm""ir or sm""ir in insert mode"
  string_diag 'key_end' 'ke''nd' '@7' "end key"
  string_diag 'key_enter' 'kent' '@8' "enter/send key"
  string_diag 'key_eol' 'kel' 'kE' "clear-to-end-of-line key"
  string_diag 'key_eos' 'ked' 'kS' "clear-to-end-of- screen key"
  string_diag 'key_exit' 'kext' '@9' "exit key"

  string_diag 'key_f0' 'kf0' 'k0' "F0 function key"
  string_diag 'key_f1' 'kf1' 'k1' "F1 function key"
  string_diag 'key_f2' 'kf2' 'k2' "F2 function key"
  string_diag 'key_f3' 'kf3' 'k3' "F3 function key"
  string_diag 'key_f4' 'kf4' 'k4' "F4 function key"
  string_diag 'key_f5' 'kf5' 'k5' "F5 function key"
  string_diag 'key_f6' 'kf6' 'k6' "F6 function key"
  string_diag 'key_f7' 'kf7' 'k7' "F7 function key"
  string_diag 'key_f8' 'kf8' 'k8' "F8 function key"
  string_diag 'key_f9' 'kf9' 'k9' "F9 function key"
  string_diag 'key_f10' 'kf10' 'k;' "F10 function key"
  string_diag 'key_f11' 'kf11' 'F1' "F11 function key"
  string_diag 'key_f12' 'kf12' 'F2' "F12 function key"
  string_diag 'key_f13' 'kf13' 'F3' "F13 function key"
  string_diag 'key_f14' 'kf14' 'F4' "F14 function key"
  string_diag 'key_f15' 'kf15' 'F5' "F15 function key"
  string_diag 'key_f16' 'kf16' 'F6' "F16 function key"
  string_diag 'key_f17' 'kf17' 'F7' "F17 function key"
  string_diag 'key_f18' 'kf18' 'F8' "F18 function key"
  string_diag 'key_f19' 'kf19' 'F9' "F19 function key"
  string_diag 'key_f20' 'kf20' 'FA' "F20 function key"
  string_diag 'key_f21' 'kf21' 'FB' "F21 function key"
  string_diag 'key_f22' 'kf22' 'FC' "F22 function key"
  string_diag 'key_f23' 'kf23' 'FD' "F23 function key"
  string_diag 'key_f24' 'kf24' 'FE' "F24 function key"
  string_diag 'key_f25' 'kf25' 'FF' "F25 function key"
  string_diag 'key_f26' 'kf26' 'FG' "F26 function key"
  string_diag 'key_f27' 'kf27' 'FH' "F27 function key"
  string_diag 'key_f28' 'kf28' 'FI' "F28 function key"
  string_diag 'key_f29' 'kf29' 'FJ' "F29 function key"
  string_diag 'key_f30' 'kf30' 'FK' "F30 function key"
  string_diag 'key_f31' 'kf31' 'FL' "F31 function key"
  string_diag 'key_f32' 'kf32' 'FM' "F32 function key"
  string_diag 'key_f33' 'kf33' 'FN' "F33 function key"
  string_diag 'key_f34' 'kf34' 'FO' "F34 function key"
  string_diag 'key_f35' 'kf35' 'FP' "F35 function key"
  string_diag 'key_f36' 'kf36' 'FQ' "F36 function key"
  string_diag 'key_f37' 'kf37' 'FR' "F37 function key"
  string_diag 'key_f38' 'kf38' 'FS' "F38 function key"
  string_diag 'key_f39' 'kf39' 'FT' "F39 function key"
  string_diag 'key_f40' 'kf40' 'FU' "F40 function key"
  string_diag 'key_f41' 'kf41' 'FV' "F41 function key"
  string_diag 'key_f42' 'kf42' 'FW' "F42 function key"
  string_diag 'key_f43' 'kf43' 'FX' "F43 function key"
  string_diag 'key_f44' 'kf44' 'FY' "F44 function key"
  string_diag 'key_f45' 'kf45' 'FZ' "F45 function key"
  string_diag 'key_f46' 'kf46' 'Fa' "F46 function key"
  string_diag 'key_f47' 'kf47' 'Fb' "F47 function key"
  string_diag 'key_f48' 'kf48' 'Fc' "F48 function key"
  string_diag 'key_f49' 'kf49' 'Fd' "F49 function key"
  string_diag 'key_f50' 'kf50' 'Fe' "F50 function key"
  string_diag 'key_f51' 'kf51' 'Ff' "F51 function key"
  string_diag 'key_f52' 'kf52' 'Fg' "F52 function key"
  string_diag 'key_f53' 'kf53' 'Fh' "F53 function key"
  string_diag 'key_f54' 'kf54' 'Fi' "F54 function key"
  string_diag 'key_f55' 'kf55' 'Fj' "F55 function key"
  string_diag 'key_f56' 'kf56' 'Fk' "F56 function key"
  string_diag 'key_f57' 'kf57' 'Fl' "F57 function key"
  string_diag 'key_f58' 'kf58' 'Fm' "F58 function key"
  string_diag 'key_f59' 'kf59' 'Fn' "F59 function key"
  string_diag 'key_f60' 'kf60' 'Fo' "F60 function key"
  string_diag 'key_f61' 'kf61' 'Fp' "F61 function key"
  string_diag 'key_f62' 'kf62' 'Fq' "F62 function key"
  string_diag 'key_f63' 'kf63' 'Fr' "F63 function key"

  string_diag 'key_find' 'kf''nd' '@0' "find key"
  string_diag 'key_help' 'kh''lp' '%1' "help key"
  string_diag 'key_home' 'kh''ome' 'kh' "home key"
  string_diag 'key_ic' 'ki''ch1' 'kI' "insert-character key"
  string_diag 'key_il' 'kil1' 'kA' "insert-line key"
  string_diag 'key_left' 'kc''ub1' 'kl' "left-arrow key"
  string_diag 'key_ll' 'kll' 'kH' "lower-left key (home down)"
  string_diag 'key_mark' 'km''rk' '%2' "mark key"
  string_diag 'key_message' 'km''sg' '%3' "message key"
  string_diag 'key_move' 'km''ov' '%4' "move key"
  string_diag 'key_next' 'kn''xt' '%5' "next key"
  string_diag 'key_np''age' 'knp' 'kN' "next-page key"
  string_diag 'key_open' 'ko''pn' '%6' "open key"
  string_diag 'key_options' 'ko''pt' '%7' "options key"
  string_diag 'key_pp''age' 'kpp' 'kP' "previous-page key"
  string_diag 'key_previous' 'kp''rv' '%8' "previous key"
  string_diag 'key_print' 'kp''rt' '%9' "print key"
  string_diag 'key_redo' 'kr''do' '%0' "redo key"
  string_diag 'key_reference' 'kr''ef' '&1' "reference key"
  string_diag 'key_refresh' 'kr''fr' '&2' "refresh key"
  string_diag 'key_replace' 'kr''pl' '&3' "replace key"
  string_diag 'key_restart' 'kr''st' '&4' "restart key"
  string_diag 'key_resume' 'kr''es' '&5' "resume key"
  string_diag 'key_right' 'kc''uf1' 'kr' "right-arrow key"
  string_diag 'key_save' 'ks''av' '&6' "save key"
  string_diag 'key_s''beg' 'kBEG' '&9' "shifted begin key"
  string_diag 'key_s''cancel' 'kCAN' '&0' "shifted cancel key"
  string_diag 'key_s''command' 'kCMD' '*1' "shifted command key"
  string_diag 'key_s''copy' 'kCPY' '*2' "shifted copy key"
  string_diag 'key_s''create' 'kCRT' '*3' "shifted create key"
  string_diag 'key_s''dc' 'kDC' '*4' "shifted delete- character key"
  string_diag 'key_s''dl' 'kDL' '*5' "shifted delete-line key"
  string_diag 'key_select' 'ks''lt' '*6' "select key"
  string_diag 'key_send' 'kEND' '*7' "shifted end key"
  string_diag 'key_s''eol' 'kEOL' '*8' "shifted clear-to- end-of-line key"
  string_diag 'key_s''exit' 'kEXT' '*9' "shifted exit key"
  string_diag 'key_sf' 'kind' 'kF' "scroll-forward key"
  string_diag 'key_s''find' 'kFND' '*0' "shifted find key"
  string_diag 'key_s''help' 'kHLP' '#1' "shifted help key"
  string_diag 'key_s''home' 'kHOM' '#2' "shifted home key"
  string_diag 'key_sic' 'kIC' '#3' "shifted insert- character key"
  string_diag 'key_s''left' 'kLFT' '#4' "shifted left-arrow key"
  string_diag 'key_s''message' 'kMSG' '%a' "shifted message key"
  string_diag 'key_s''move' 'kMOV' '%b' "shifted move key"
  string_diag 'key_s''next' 'kNXT' '%c' "shifted next key"
  string_diag 'key_s''options' 'kOPT' '%d' "shifted options key"
  string_diag 'key_s''previous' 'kPRV' '%e' "shifted previous key"
  string_diag 'key_s''print' 'kPRT' '%f' "shifted print key"
  string_diag 'key_s''r' 'kri' 'kR' "scroll-backward key"
  string_diag 'key_s''redo' 'kRDO' '%g' "shifted redo key"
  string_diag 'key_s''replace' 'kRPL' '%h' "shifted replace key"
  string_diag 'key_s''right' 'kRIT' '%i' "shifted right-arrow key"
  string_diag 'key_s''rs''ume' 'kRES' '%j' "shifted resume key"
  string_diag 'key_s''save' 'kSAV' '!1' "shifted save key"
  string_diag 'key_s''suspend' 'kSPD' '!2' "shifted suspend key"
  string_diag 'key_stab' 'kh''ts' 'kT' "set-tab key"
  string_diag 'key_s''undo' 'kUND' '!3' "shifted undo key"
  string_diag 'key_suspend' 'ks''pd' '&7' "suspend key"
  string_diag 'key_undo' 'ku''nd' '&8' "undo key"
  string_diag 'key_up' 'kc''uu1' 'ku' "up-arrow key"
  string_diag 'keypad_local' 'rm''kx' 'ke''' "leave 'keyboard_transmit' mode"
  string_diag 'keypad_xm''it' 'sm''kx' 'ks' "enter 'keyboard_transmit' mode"
  string_diag 'lab_f0' 'lf0' 'l0' "label on function key f0 if not f0"
  string_diag 'lab_f1' 'lf1' 'l1' "label on function key f1 if not f1"
  string_diag 'lab_f2' 'lf2' 'l2' "label on function key f2 if not f2"
  string_diag 'lab_f3' 'lf3' 'l3' "label on function key f3 if not f3"
  string_diag 'lab_f4' 'lf4' 'l4' "label on function key f4 if not f4"
  string_diag 'lab_f5' 'lf5' 'l5' "label on function key f5 if not f5"
  string_diag 'lab_f6' 'lf6' 'l6' "label on function key f6 if not f6"
  string_diag 'lab_f7' 'lf7' 'l7' "label on function key f7 if not f7"
  string_diag 'lab_f8' 'lf8' 'l8' "label on function key f8 if not f8"
  string_diag 'lab_f9' 'lf9' 'l9' "label on function key f9 if not f9"
  string_diag 'lab_f10' 'lf10' 'la' "label on function key f10 if not f10"
  string_diag 'label_format' 'fln' 'Lf' "label format"
  string_diag 'label_off' 'rm''ln' 'LF' "turn off soft labels"
  string_diag 'label_on' 'sm''ln' 'LO' "turn on soft labels"
  string_diag 'meta_off' 'rmm' 'mo' "turn off meta mode"
  string_diag 'meta_on' 'smm' 'mm' "turn on meta mode (8th-bit on)"
  string_diag 'micro_column_address' 'mh''pa' 'ZY' "Like column_address in micro mode"
  string_diag 'micro_down' 'mc''ud1' 'ZZ' "Like cursor_down in micro mode"
  string_diag 'micro_left' 'mc''ub1' 'Za' "Like cursor_left in micro mode"
  string_diag 'micro_right' 'mc''uf1' 'Zb' "Like cursor_right in micro mode"
  string_diag 'micro_row_address' 'mv''pa' 'Zc' "Like row_address #1 in micro mode"
  string_diag 'micro_up' 'mc''uu1' 'Zd' "Like cursor_up in micro mode"
  string_diag 'newline' 'nel' 'nw' "newline (behave like cr followed by lf)"
  string_diag 'order_of_pins' 'por''der' 'Ze' "Match software bits to print-head pins"
  string_diag 'orig_colors' 'oc' 'oc' "Set all color pairs to the original ones"
  string_diag 'orig_pair' 'op' 'op' "Set default pair to its original value"
  string_diag 'pad_char' 'pad' 'pc' "padding char (instead of null)"
  string_diag 'parm_dch' 'dch' 'DC' "delete #1 characters (P*)"
  string_diag 'parm_delete_line' 'dl' 'DL' "delete #1 lines (P*)"
  string_diag 'parm_down_micro' 'mc''ud' 'Zf' "Like parm_down_cursor in micro mode"
  string_diag 'parm_ich' 'ich' 'IC' "insert #1 characters (P*)"
  string_diag 'parm_index' 'in''dn' 'SF' "scroll forward #1 lines (P)"
  string_diag 'parm_insert_line' 'il' 'AL' "insert #1 lines (P*)"
  string_diag 'parm_left_micro' 'mc''ub' 'Zg' "Like parm_left_cursor in micro mode"
  string_diag 'parm_right_micro' 'mc''uf' 'Zh' "Like parm_right_cursor in micro mode"
  string_diag 'parm_r''index' 'rin' 'SR' "scroll back #1 lines (P)"
  string_diag 'parm_up_micro' 'mc''uu' 'Zi' "Like parm_up_cursor in micro mode"
  string_diag 'pkey_key' 'pf''key' 'pk' "program function key #1 to type string #2"
  string_diag 'pkey_local' 'pf''loc' 'pl' "program function key #1 to execute string #2"
  string_diag 'pkey_xm''it' 'pfx' 'px' "program function key #1 to transmit string #2"
  string_diag 'p''lab_norm' 'pln' 'pn' "program label #1 to show string #2"
  string_diag 'print_screen' 'mc0' 'ps' "print contents of screen"
  string_diag 'pr''tr_non' 'mc5p' 'pO' "turn on printer for #1 bytes"
  string_diag 'pr''tr_off' 'mc4' 'pf' "turn off printer"
  string_diag 'pr''tr_on' 'mc5' 'po' "turn on printer"
  string_diag 'pulse' 'pulse' 'PU' "select pulse dialing"
  string_diag 'quick_dial' 'qd''ial' 'QD''' "dial number #1 without checking"
  string_diag 'remove_clock' 'rm''clk' 'RC' "remove clock"
  string_diag 'repeat_char' 'rep' 'rp' "repeat char #1 #2 times (P*)"
  string_diag 'req_for_input' 'rfi' 'RF' "send next input char (for pt""ys)"
  string_diag 'reset_1string' 'rs1' 'r1' "reset string"
  string_diag 'reset_2string' 'rs2' 'r2' "reset string"
  string_diag 'reset_3string' 'rs3' 'r3' "reset string"
  string_diag 'reset_file' 'rf' 'rf' "name of reset file"
  string_diag 'scroll_forward' 'ind' 'sf' "scroll text up (P)"
  string_diag 'scroll_reverse' 'ri' 'sr' "scroll text down (P)"
  string_diag 'select_char_set' 'scs' 'Zj' "Select character set, #1"
  string_diag 'set_attributes' 'sgr' 'sa' "define video attributes #1-#9 (PG9)"
  string_diag 'set_background' 'se''tb' 'Sb' "Set background color #1"
  string_diag 'set_bottom_margin' 'sm''gb' 'Zk' "Set bottom margin at current line"
  string_diag 'set_bottom_margin_parm' 'sm''gbp' 'Zl' "Set bottom margin at line #1 or (if sm""gtp is not given) #2 lines from bottom"
  string_diag 'set_clock' 'sc''lk' 'SC' "set clock, #1 hrs #2 mi""ns #3 secs"
  string_diag 'set_color_pair' 'scp' 'sp' "Set current color pair to #1"
  string_diag 'set_foreground' 'se''tf' 'Sf' "Set foreground color #1"
  string_diag 'set_left_margin' 'sm''gl' 'ML' "set left soft margin at current column.   See sm""gl. (ML is not in BSD termcap)."
  string_diag 'set_left_margin_parm' 'sm''glp' 'Zm' "Set left (right) margin at column #1"
  string_diag 'set_right_margin' 'sm''gr' 'MR' "set right soft margin at current column"
  string_diag 'set_right_margin_parm' 'sm''grp' 'Zn' "Set right margin at column #1"
  string_diag 'set_tab' 'hts' 'st' "set a tab in every row, current columns"
  string_diag 'set_top_margin' 'sm''gt' 'Zo' "Set top margin at current line"
  string_diag 'set_top_margin_parm' 'sm''gtp' 'Zp' "Set top (bottom) margin at row #1"
  string_diag 'set_window' 'wind' 'wi' "current window is lines #1-#2 cols #3-#4"
  string_diag 'start_bit_image' 'sb''im' 'Zq' "Start printing bit image graphics"
  string_diag 'start_char_set_def' 'sc''sd' 'Zr' "Start character set definition #1, with #2 characters in the set"
  string_diag 'stop_bit_image' 'rb''im' 'Zs' "Stop printing bit image graphics"
  string_diag 'stop_char_set_def' 'rc''sd' 'Zt' "End definition of character set #1"
  string_diag 'subscript_characters' 'su''bcs' 'Zu' "List of subscript""able characters"
  string_diag 'superscript_characters' 'su''pcs' 'Zv' "List of superscript""able characters"
  string_diag 'tab' 'ht' 'ta' "tab to next 8-space hardware tab stop"
  string_diag 'these_cause_cr' 'do''cr' 'Zw' "Printing any of these characters causes CR"
  string_diag 'to_status_line' 'tsl' 'ts' "move to status line, column #1"
  string_diag 'tone' 'tone' 'TO' "select touch tone dialing"
  string_diag 'underline_char' 'uc' 'uc' "underline char and move past it"
  string_diag 'up_half_line' 'hu' 'hu' "half a line up"
  string_diag 'user0' 'u0' 'u0' "User string #0"
  string_diag 'user1' 'u1' 'u1' "User string #1"
  string_diag 'user2' 'u2' 'u2' "User string #2"
  string_diag 'user3' 'u3' 'u3' "User string #3"
  string_diag 'user4' 'u4' 'u4' "User string #4"
  string_diag 'user5' 'u5' 'u5' "User string #5"
  string_diag 'user6' 'u6' 'u6' "User string #6"
  string_diag 'user7' 'u7' 'u7' "User string #7"
  string_diag 'user8' 'u8' 'u8' "User string #8"
  string_diag 'user9' 'u9' 'u9' "User string #9"
  string_diag 'wait_tone' 'wait' 'WA' "wait for dial-tone"
  string_diag 'xo''ff_character' 'xo''ffc' 'XF' "X""OFF character"
  string_diag 'xon_character' 'xo''nc' 'XN' "XON character"
  string_diag 'zero_motion' 'ze''rom' 'Zx' "No motion for subsequent character"
  string_diag 'alt_scancode_esc' 'sc''esa' 'S8' "Alternate escape for scancode emulation"
  string_diag 'bit_image_carriage_return' 'bi''cr' 'Yv' "Move to beginning of same row"
  string_diag 'bit_image_newline' 'bi''nel' 'Zz' "Move to next row of the bit image"
  string_diag 'bit_image_repeat' 'bi''rep' 'Xy' "Repeat bit image cell #1 #2 times"
  string_diag 'char_set_names' 'cs''nm' 'Zy' "Produce #1'th item from list of character set names"
  string_diag 'code_set_init' 'cs''in' 'ci' "Init sequence for multiple code""sets"
  string_diag 'color_names' 'co''lo''rnm' 'Yw' "Give name for color #1"
  string_diag 'define_bit_image_region' 'de''fbi' 'Yx' "Define rectangular bit image region"
  string_diag 'device_type' 'de''vt' 'dv' "Indicate language/codeset support"
  string_diag 'display_pc_char' 'di''spc' 'S1' "Display PC character #1"
  string_diag 'end_bit_image_region' 'en''dbi' 'Yy' "End a bit-image region"
  string_diag 'enter_pc_charset_mode' 'sm''pch' 'S2' "Enter PC character display mode"
  string_diag 'enter_scancode_mode' 'sm''sc' 'S4' "Enter PC scancode mode"
  string_diag 'exit_pc_charset_mode' 'rm''pch' 'S3' "Exit PC character display mode"
  string_diag 'exit_scancode_mode' 'rm''sc' 'S5' "Exit PC scancode mode"
  string_diag 'get_mouse' 'ge''tm' 'Gm' "Curses should get button events, parameter #1 not documented."
  string_diag 'key_mouse' 'km''ous' 'Km' "Mouse event has occurred"
  string_diag 'mouse_info' 'mi''nfo' 'Mi' "Mouse status information"
  string_diag 'pc_term_options' 'pc''trm' 'S6' "PC terminal options"
  string_diag 'pkey_pl''ab' 'pf''xl' 'xl' "Program function key #1 to type string #2 and show string #3"
  string_diag 'req_mouse_pos' 're''qmp' 'RQ' "Request mouse position"
  string_diag 'scancode_escape' 'sc''esc' 'S7' "Escape for scancode emulation"
  string_diag 'set0_des_seq' 's0ds' 's0' "Shift to codeset 0 (EUC set 0, ASCII)"
  string_diag 'set1_des_seq' 's1ds' 's1' "Shift to codeset 1"
  string_diag 'set2_des_seq' 's2ds' 's2' "Shift to codeset 2"
  string_diag 'set3_des_seq' 's3ds' 's3' "Shift to codeset 3"
  string_diag 'set_a_background' 'se''tab' 'AB' "Set background color to #1, using ANSI escape"
  string_diag 'set_a_foreground' 'se''taf' 'AF' "Set foreground color to #1, using ANSI escape"
  string_diag 'set_color_band' 'set''color' 'Yz' "Change to ribbon color #1"
  string_diag 'set_lr_margin' 'sm''glr' 'ML' "Set both left and right margins to #1, #2. (ML is not in BSD termcap)."
  string_diag 'set_page_length' 'sl''ines' 'YZ' "Set page length to #1 lines"
  string_diag 'set_tb_margin' 'sm''gtb' 'MT' "Sets both top and bottom margins to #1, #2"
}

# TODO https://github.com/gnachman/iTerm2/tree/master/tests


printf '\e[0m%s\e[0m\n' 'Clear all special attributes'
printf '\e[1m%s\e[0m\n' 'Bold or increased intensity'
printf '\e[22m%s\e[0m\n' 'Cancel bold or dim attribute only (VT220)'
printf '\e[2m%s\e[0m\n' 'Dim or secondary color on GIGI  (superscript on XXXXXX)'
printf '\e[3m%s\e[0m\n' 'Italic                          (subscript on XXXXXX)'
printf '\e[4m%s\e[0m\n' 'Underscore, \\e[0;4m = Clear, then set underline only'
printf '\e[24m%s\e[0m\n' 'Cancel underline attribute only (VT220)'
printf '\e[5m%s\e[0m\n' 'Slow blink'
printf '\e[25m%s\e[0m\n' 'Cancel fast or slow blink attribute only (VT220)'
printf '\e[6m%s\e[0m\n' 'Fast blink                      (overscore on XXXXXX)'
printf '\e[7m%s\e[0m\n' 'Negative image, \\e[0;1;7m = Bold + Inverse'
printf '\e[27m%s\e[0m\n' 'Cancel negative image attribute only (VT220)'
printf '\e[8m%s\e[0m\n' 'Concealed (do not display character echoed locally)'
printf '\e[9m%s\e[0m\n' 'Reserved for future standardization'
printf '\e[10m%s\e[0m\n' 'Select primary font (LA100)'
printf '\e[11m%s\e[0m\n' 'Selete alternate font (LA100 has 11 thru 14)'
printf '\e[19m%s\e[0m\n' 'unknown'
printf '\e[20m%s\e[0m\n' 'FRAKTUR  26 characters include β, umlauts...'
sleep 10

main "$@"
