#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

setup() {
  setup_test_environment
  unset _BATTERY_REVAMPED_RENDER_LOADED
  source "${BATS_TEST_DIRNAME}/../../../src/lib/battery/render.sh"
}

teardown() {
  cleanup_test_environment
}

@test "render.sh - battery_tier maps percent to tiers 1..8" {
  [[ "$(battery_tier 0)" == "1" ]]
  [[ "$(battery_tier 100)" == "8" ]]
  [[ "$(battery_tier 50)" == "4" ]]
  [[ "$(battery_tier xx)" == "1" ]]
}

@test "render.sh - battery_charge_icon is empty on cold start" {
  [[ -z "$(battery_charge_icon "")" ]]
}

@test "render.sh - battery_charge_icon returns the tier default" {
  [[ "$(battery_charge_icon 100)" == "█" ]]
}

@test "render.sh - battery_charge_icon honors a custom tier icon" {
  set_tmux_option "@battery_revamped_charge_tier8_icon" "FULL"
  [[ "$(battery_charge_icon 100)" == "FULL" ]]
}

@test "render.sh - battery_charge_color is empty on cold start" {
  [[ -z "$(battery_charge_color "")" ]]
}

@test "render.sh - battery_charge_color returns the configured color" {
  set_tmux_option "@battery_revamped_charge_tier8_fg_color" "#[fg=green]"
  [[ "$(battery_charge_color 100 fg)" == "#[fg=green]" ]]
}

@test "render.sh - battery_status_icon returns defaults per status" {
  [[ "$(battery_status_icon charging)" == "+" ]]
  [[ "$(battery_status_icon discharging)" == "-" ]]
  [[ "$(battery_status_icon charged)" == "=" ]]
  [[ "$(battery_status_icon attached)" == "!" ]]
  [[ "$(battery_status_icon unknown)" == "?" ]]
}

@test "render.sh - battery_status_icon honors a custom icon" {
  set_tmux_option "@battery_revamped_status_charging_icon" "BOLT"
  [[ "$(battery_status_icon charging)" == "BOLT" ]]
}

@test "render.sh - battery_status_color returns the configured color" {
  set_tmux_option "@battery_revamped_status_discharging_bg_color" "#[bg=red]"
  [[ "$(battery_status_color discharging bg)" == "#[bg=red]" ]]
}

@test "render.sh - battery_render_percentage formats the value" {
  [[ -z "$(battery_render_percentage "")" ]]
  [[ "$(battery_render_percentage 83)" == "83%" ]]
}

@test "render.sh - battery_render_graph draws a proportional bar" {
  [[ "$(battery_render_graph 50)" == "█████░░░░░" ]]
  [[ "$(battery_render_graph 0)" == "░░░░░░░░░░" ]]
  [[ "$(battery_render_graph 100)" == "██████████" ]]
}

@test "render.sh - battery_render_graph is empty for junk" {
  [[ -z "$(battery_render_graph xx)" ]]
}

@test "render.sh - battery_render_graph honors custom width and chars" {
  set_tmux_option "@battery_revamped_graph_width" "4"
  set_tmux_option "@battery_revamped_graph_full" "#"
  set_tmux_option "@battery_revamped_graph_empty" "-"
  [[ "$(battery_render_graph 50)" == "##--" ]]
}

@test "render.sh - battery_render_remain formats the value" {
  [[ -z "$(battery_render_remain "")" ]]
  [[ "$(battery_render_remain "4:32")" == "4:32" ]]
}

@test "render.sh - battery_render_watts formats the value" {
  [[ -z "$(battery_render_watts "")" ]]
  [[ "$(battery_render_watts 60)" == "60W" ]]
}

@test "render.sh - battery_render_cycles formats the value" {
  [[ -z "$(battery_render_cycles "")" ]]
  [[ "$(battery_render_cycles 142)" == "142" ]]
}

@test "render.sh - battery_render_health formats the value" {
  [[ -z "$(battery_render_health "")" ]]
  [[ "$(battery_render_health 96)" == "96%" ]]
}

@test "render.sh - battery_charge_color passes a named color through verbatim" {
  set_tmux_option "@battery_revamped_charge_tier8_fg_color" "#[fg=red]"
  [[ "$(battery_charge_color 100 fg)" == "#[fg=red]" ]]
}

@test "render.sh - battery_charge_color passes a 256 color through verbatim" {
  set_tmux_option "@battery_revamped_charge_tier8_fg_color" "#[fg=colour203]"
  [[ "$(battery_charge_color 100 fg)" == "#[fg=colour203]" ]]
}

@test "render.sh - battery_charge_color passes a hex color through verbatim" {
  set_tmux_option "@battery_revamped_charge_tier8_fg_color" "#[fg=#f38ba8]"
  [[ "$(battery_charge_color 100 fg)" == "#[fg=#f38ba8]" ]]
}

@test "render.sh - battery_charge_color passes a hex fg and bg pair through verbatim" {
  set_tmux_option "@battery_revamped_charge_tier8_fg_color" "#[fg=#f38ba8,bg=#1e1e2e]"
  [[ "$(battery_charge_color 100 fg)" == "#[fg=#f38ba8,bg=#1e1e2e]" ]]
}

@test "render.sh - battery_charge_color passes a bright color through verbatim" {
  set_tmux_option "@battery_revamped_charge_tier8_fg_color" "#[fg=brightred]"
  [[ "$(battery_charge_color 100 fg)" == "#[fg=brightred]" ]]
}

@test "render.sh - battery_status_color passes a named color through verbatim" {
  set_tmux_option "@battery_revamped_status_charging_fg_color" "#[fg=red]"
  [[ "$(battery_status_color charging fg)" == "#[fg=red]" ]]
}

@test "render.sh - battery_status_color passes a 256 color through verbatim" {
  set_tmux_option "@battery_revamped_status_charging_fg_color" "#[fg=colour203]"
  [[ "$(battery_status_color charging fg)" == "#[fg=colour203]" ]]
}

@test "render.sh - battery_status_color passes a hex color through verbatim" {
  set_tmux_option "@battery_revamped_status_charging_fg_color" "#[fg=#f38ba8]"
  [[ "$(battery_status_color charging fg)" == "#[fg=#f38ba8]" ]]
}

@test "render.sh - battery_status_color passes a hex fg and bg pair through verbatim" {
  set_tmux_option "@battery_revamped_status_charging_fg_color" "#[fg=#f38ba8,bg=#1e1e2e]"
  [[ "$(battery_status_color charging fg)" == "#[fg=#f38ba8,bg=#1e1e2e]" ]]
}

@test "render.sh - battery_status_color passes a bright color through verbatim" {
  set_tmux_option "@battery_revamped_status_charging_fg_color" "#[fg=brightred]"
  [[ "$(battery_status_color charging fg)" == "#[fg=brightred]" ]]
}
