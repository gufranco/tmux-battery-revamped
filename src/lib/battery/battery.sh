#!/usr/bin/env bash
#
# battery.sh: battery percentage, status, remaining time, and charging watts.
#
# Pure parsers turn probe output into values. Reader functions wrap the host
# probes behind seams that tests override. One worker calls every reader once.

[[ -n "${_BATTERY_REVAMPED_BATTERY_LOADED:-}" ]] && return 0
_BATTERY_REVAMPED_BATTERY_LOADED=1

_BATTERY_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${_BATTERY_LIB_DIR}/../utils/platform.sh"
# shellcheck source=/dev/null
source "${_BATTERY_LIB_DIR}/../utils/has-command.sh"

# battery_norm_status RAW -> charging|discharging|charged|attached|unknown.
battery_norm_status() {
  local s
  s=$(printf '%s' "${1}" | tr '[:upper:]' '[:lower:]')
  case "${s}" in
    *"not charging"*) echo "attached" ;;
    *discharging*)    echo "discharging" ;;
    *charging*)       echo "charging" ;;
    *charged*|*full*) echo "charged" ;;
    *)                echo "unknown" ;;
  esac
}

# battery_pct_from_pmset TEXT -> integer percent from `pmset -g batt`.
battery_pct_from_pmset() {
  printf '%s\n' "${1}" | grep -oE '[0-9]+%' | head -1 | tr -d '%'
}

# battery_status_from_pmset TEXT -> normalized status from `pmset -g batt`.
battery_status_from_pmset() {
  local line raw
  line=$(printf '%s\n' "${1}" | grep -E '[0-9]+%' | head -1)
  raw=$(printf '%s' "${line}" | awk -F';' '{ print $2 }')
  battery_norm_status "${raw}"
}

# battery_remain_from_pmset TEXT -> "H:MM" remaining, empty when not estimated.
battery_remain_from_pmset() {
  printf '%s\n' "${1}" | grep -oE '[0-9]+:[0-9]+' | head -1
}

# battery_watts_from_profiler TEXT -> charging watts integer, empty when absent.
battery_watts_from_profiler() {
  printf '%s\n' "${1}" | grep -i "Wattage" | grep -oE '[0-9]+' | head -1
}

# Host-probe seams.
_read_pmset() { pmset -g batt 2>/dev/null; }
_read_sys_capacity() { cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1; }
_read_sys_status() { cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1; }
_read_acpi() { acpi -b 2>/dev/null | head -1; }
_read_profiler() { system_profiler SPPowerDataType 2>/dev/null; }
_sys_battery_present() { compgen -G "/sys/class/power_supply/BAT*/capacity" >/dev/null 2>&1; }

read_battery_percentage() {
  if is_macos; then
    battery_pct_from_pmset "$(_read_pmset)"
  elif _sys_battery_present; then
    local cap
    cap=$(_read_sys_capacity)
    [[ "${cap}" =~ ^[0-9]+$ ]] && echo "${cap}"
  elif has_command acpi; then
    printf '%s\n' "$(_read_acpi)" | grep -oE '[0-9]+%' | head -1 | tr -d '%'
  fi
}

read_battery_status() {
  if is_macos; then
    battery_status_from_pmset "$(_read_pmset)"
  elif _sys_battery_present; then
    battery_norm_status "$(_read_sys_status)"
  elif has_command acpi; then
    battery_norm_status "$(_read_acpi)"
  else
    echo "unknown"
  fi
}

read_battery_remain() {
  if is_macos; then
    battery_remain_from_pmset "$(_read_pmset)"
  elif has_command acpi; then
    printf '%s\n' "$(_read_acpi)" | grep -oE '[0-9]+:[0-9]+' | head -1
  fi
}

read_battery_watts() {
  if is_macos; then
    battery_watts_from_profiler "$(_read_profiler)"
  fi
}

export -f battery_norm_status
export -f battery_pct_from_pmset
export -f battery_status_from_pmset
export -f battery_remain_from_pmset
export -f battery_watts_from_profiler
export -f _read_pmset
export -f _read_sys_capacity
export -f _read_sys_status
export -f _read_acpi
export -f _read_profiler
export -f _sys_battery_present
export -f read_battery_percentage
export -f read_battery_status
export -f read_battery_remain
export -f read_battery_watts
