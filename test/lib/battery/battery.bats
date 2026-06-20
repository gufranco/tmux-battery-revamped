#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

PMSET=$' -InternalBattery-0 (id=123)\t83%; discharging; 4:32 remaining present: true'

setup() {
  setup_test_environment
  unset _BATTERY_REVAMPED_BATTERY_LOADED
  source "${BATS_TEST_DIRNAME}/../../../src/lib/battery/battery.sh"
}

teardown() {
  cleanup_test_environment
}

@test "battery.sh - battery_norm_status normalizes every state" {
  [[ "$(battery_norm_status 'Discharging')" == "discharging" ]]
  [[ "$(battery_norm_status 'Charging')" == "charging" ]]
  [[ "$(battery_norm_status 'Charged')" == "charged" ]]
  [[ "$(battery_norm_status 'Full')" == "charged" ]]
  [[ "$(battery_norm_status 'Not charging')" == "attached" ]]
  [[ "$(battery_norm_status 'weird')" == "unknown" ]]
}

@test "battery.sh - battery_pct_from_pmset reads the percentage" {
  [[ "$(battery_pct_from_pmset "${PMSET}")" == "83" ]]
}

@test "battery.sh - battery_status_from_pmset reads the status" {
  [[ "$(battery_status_from_pmset "${PMSET}")" == "discharging" ]]
}

@test "battery.sh - battery_remain_from_pmset reads the remaining time" {
  [[ "$(battery_remain_from_pmset "${PMSET}")" == "4:32" ]]
}

@test "battery.sh - battery_watts_from_profiler reads the wattage" {
  [[ "$(battery_watts_from_profiler "Wattage (W): 60")" == "60" ]]
}

@test "battery.sh - read_battery_percentage uses pmset on macOS" {
  _PLATFORM_OS_CACHE="Darwin"
  _read_pmset() { echo "${PMSET}"; }
  [[ "$(read_battery_percentage)" == "83" ]]
}

@test "battery.sh - read_battery_percentage reads /sys on Linux" {
  _PLATFORM_OS_CACHE="Linux"
  _sys_battery_present() { return 0; }
  _read_sys_capacity() { echo "77"; }
  [[ "$(read_battery_percentage)" == "77" ]]
}

@test "battery.sh - read_battery_percentage falls back to acpi" {
  _PLATFORM_OS_CACHE="Linux"
  _sys_battery_present() { return 1; }
  has_command() { [[ "$1" == "acpi" ]]; }
  _read_acpi() { echo "Battery 0: Discharging, 64%, 03:00:00 remaining"; }
  [[ "$(read_battery_percentage)" == "64" ]]
}

@test "battery.sh - read_battery_status uses pmset on macOS" {
  _PLATFORM_OS_CACHE="Darwin"
  _read_pmset() { echo "${PMSET}"; }
  [[ "$(read_battery_status)" == "discharging" ]]
}

@test "battery.sh - read_battery_status reads /sys on Linux" {
  _PLATFORM_OS_CACHE="Linux"
  _sys_battery_present() { return 0; }
  _read_sys_status() { echo "Charging"; }
  [[ "$(read_battery_status)" == "charging" ]]
}

@test "battery.sh - read_battery_status falls back to acpi" {
  _PLATFORM_OS_CACHE="Linux"
  _sys_battery_present() { return 1; }
  has_command() { [[ "$1" == "acpi" ]]; }
  _read_acpi() { echo "Battery 0: Discharging, 64%"; }
  [[ "$(read_battery_status)" == "discharging" ]]
}

@test "battery.sh - read_battery_status is unknown with no source" {
  _PLATFORM_OS_CACHE="Linux"
  _sys_battery_present() { return 1; }
  has_command() { return 1; }
  [[ "$(read_battery_status)" == "unknown" ]]
}

@test "battery.sh - read_battery_remain uses pmset on macOS" {
  _PLATFORM_OS_CACHE="Darwin"
  _read_pmset() { echo "${PMSET}"; }
  [[ "$(read_battery_remain)" == "4:32" ]]
}

@test "battery.sh - read_battery_remain uses acpi on Linux" {
  _PLATFORM_OS_CACHE="Linux"
  has_command() { [[ "$1" == "acpi" ]]; }
  _read_acpi() { echo "Battery 0: Discharging, 64%, 03:00:00 remaining"; }
  [[ "$(read_battery_remain)" == "03:00" ]]
}

@test "battery.sh - read_battery_watts uses system_profiler on macOS" {
  _PLATFORM_OS_CACHE="Darwin"
  _read_profiler() { echo "Wattage (W): 60"; }
  [[ "$(read_battery_watts)" == "60" ]]
}

@test "battery.sh - read_battery_watts is empty off macOS" {
  _PLATFORM_OS_CACHE="Linux"
  [[ -z "$(read_battery_watts)" ]]
}
