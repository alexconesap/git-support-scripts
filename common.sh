#!/bin/sh
# Shared utilities for the support/*.sh scripts.
# Source this from the top of a script:
#
#   . "$(dirname -- "$0")/common.sh"
#
# Provides colored logging helpers. Colors are disabled automatically when
# stdout is not a terminal or when NO_COLOR is set in the environment.
#
# POSIX-compatible: works under both /bin/sh and bash.

# Guard against double-sourcing.
if [ -n "${_COMMON_SH_LOADED:-}" ]; then
    return 0 2>/dev/null || exit 0
fi
_COMMON_SH_LOADED=1

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    _c_reset=$(printf '\033[0m')
    _c_bold=$(printf '\033[1m')
    _c_red=$(printf '\033[31m')
    _c_green=$(printf '\033[32m')
    _c_yellow=$(printf '\033[33m')
    _c_blue=$(printf '\033[34m')
    _c_cyan=$(printf '\033[36m')
    _c_gray=$(printf '\033[90m')
    _c_white=$(printf '\033[97m')
else
    _c_reset=''; _c_bold=''; _c_red=''; _c_green=''
    _c_yellow=''; _c_blue=''; _c_cyan=''; _c_gray=''; _c_white=''
fi

msg_info()    { printf '%sℹ %s%s\n' "$_c_blue"   "$*" "$_c_reset"; }
msg_ok()      { printf '%s✔ %s%s\n' "$_c_green"  "$*" "$_c_reset"; }
msg_warn()    { printf '%s⚠ %s%s\n' "$_c_yellow" "$*" "$_c_reset" >&2; }
msg_error()   { printf '%s✖ %s%s\n' "$_c_red"    "$*" "$_c_reset" >&2; }
msg_section() { printf '\n%s%s▶ %s%s\n' "$_c_bold" "$_c_white" "$*" "$_c_reset"; }
msg_prompt()  { printf '%s%s%s ' "$_c_bold" "$*" "$_c_reset"; }
msg_dim()     { printf '%s%s%s\n' "$_c_gray" "$*" "$_c_reset"; }
msg_bullet()  { printf '  %s•%s %s\n' "$_c_cyan" "$_c_reset" "$*"; }

msg_rule() {
    cols=${COLUMNS:-}
    [ -z "$cols" ] && cols=$(tput cols 2>/dev/null || echo 80)
    printf '%s' "$_c_gray"
    printf '%*s' "$cols" '' | tr ' ' '-'
    printf '%s\n' "$_c_reset"
}
