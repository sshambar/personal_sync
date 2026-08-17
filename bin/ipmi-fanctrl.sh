#!/bin/bash
# -*- mode: sh; sh-basic-offset: 4; indent-tabs-mode: nil; -*-
# vim:set ft=sh et sts=4:
# Copyright 2024 - 2024, Jaremy Hatler
# Copyright, Scott Shambarger
# SPDX-License-Identifier: MIT

# FIXME TESTING
#  for i in $(seq 1 $(nproc)); do while :; do :; done & done
#  while :; do echo killing %+; kill %+ || break; sleep 0.1; done

## Dell R630 Fan Control Script

# This script controls the fan speed on a Dell r630 server in response to the CPU temperature.
#
# In some cases (nonstandard firmware, aftermarket PCI cards, etc.), the internal fan controller
# will consistently maintain high RPMs. This script uses IPMI to enable manual fan control and set
# the fan speed across all fans. An exit trap is used to ensure automatic fan control is enabled
# upon exiting. On each iteration, the script logs its data and any changes it makes.
#
# A control loop is used which monitors the CPU package temperatures and inlet temp
# and adjusts the fan speeds in response. The user can set the parameters of this control loop in
# the section below, including the loop delay. At a high level, the control loop begins by setting
# the fans to the configured start speed. It will then use the difference between the target and
# actual package temperatures to determine whether to increase or decrease the fan speed, and by
# how much.
#
# If the packages are at or below the target temp, the control loop will reduce the fans speeds
# until an equilibrium is reached. If the inlet temperature is higher than the target, it plus
# the configured hysteresis offset will be used as the target.
#
# If the package alarm temperature is met, the fans will immediately be set to their configured
# maximums until the temperature begins to drop. If the configured critical temperature is met
# for longer than the specified hysteresis wait, the user-specified critical event command will
# be run. The script becomes more aggressive as the package temperature
# near the package alarm temperature.

# Proof of concept commands:
#   Get Package 0 Temp: cat /sys/devices/platform/coretemp.0/hwmon/hwmon*/temp1_input
#   Get Package 1 Temp: cat /sys/devices/platform/coretemp.1/hwmon/hwmon*/temp1_input
#   Get Inlet Temp: ipmitool sensor get 'Inlet Temp'
#   Enable manual fan control: ipmitool raw 0x30 0x30 0x01 0x00
#   Disable manual fan control: ipmitool raw 0x30 0x30 0x01 0x01
#   Set Fan Speeds to 0%: ipmitool raw 0x30 0x30 0x02 0xff 0x00
#   Set Fan Speeds to 100%: ipmitool raw 0x30 0x30 0x02 0xff 0x64


## User Parameters

DEBUG= # Enable debugging
DRYRUN= # Enable dry-run
#LOG=/var/log/fanctrl.log # Logfile
TARGET_TEMP=39 # The target temperature in Celsius
HYSTERESIS_OFFSET=5 # The hysteresis offset in Celsius
LOOP_DELAY=10 # The delay between each loop iteration in seconds
MIN_SPEED=20 # The minimum fan speed in percent
MAX_SPEED=90 # The maximum fan speed in percent
PACKAGE_ALARM_TEMP=70 # The package alarm temperature in Celsius
CRITICAL_TEMP=85 # The critical temperature in Celsius
HYSTERESIS_WAIT=300 # The hysteresis wait time in seconds
CRITICAL_EVENT_COMMAND="echo FIXME shutdown -h now" # The command to run when the critical temperature is met
HYSTERESIS_MULTIPLIER="2.0" # The multiplier for the temperature hysteresis

TEMP_STEPS=(30 40 60)
MAX_PWM_STEPS=("$MIN_SPEED" 50 "$MAX_SPEED")

## Exit Trap

function _exit_trap() {
    # Ensure automatic fan control is enabled upon exiting
    _disable_manual_fan_control
}

## Functions

function _err() { echo "$*" >&2; }
function _debug() { [[ $DEBUG ]] && _err "$*"; return 0; }

function _log_err() {
    # writes log to stdout (for logging) and stderr
    [[ $LOG ]] && echo "$*"
    _err "$*"
}

function _die() { # <msg>...
    _log_err "$*"
    exit 1
}

function _get_pkg_temp() { # <var>
    # Returns the average of all the platform core temperatures
    local _acc=0 _count=0 _sens
    for _core in /sys/devices/platform/coretemp.*; do
        for _sens in "$_core"/hwmon/hwmon*; do
            _acc=$(( _acc + $(< "$_sens"/temp1_input) ))
            _count=$(( _count + 1000 ))
        done
    done
    (( _count == 0 )) &&
        _die "Failed to find any package temperatures!"
    printf -v "$1" '%d' $((_acc / _count))
}

function _cache_timeout() { # <secs>
    [[ $1 ]] || return 0
    [[ $SECONDS -ge $(($1 + 60)) ]]
}

function _get_sensor_reading() { # <var> <sensor>
    local _line
    while read -r _line; do
        [[ $_line == "Sensor Reading"* ]] || continue
        _line=${_line#*: }
        printf -v "$1" '%s' "${_line%% *}"
    done < <(ipmitool sensor get "$2")
}

_INLET_TEMP=
_INLET_TIME=
function _get_inlet_temp() { # <var>
    # Returns the inlet temperature
    _cache_timeout "$_INLET_TIME" && _INLET_TEMP=
    [[ $_INLET_TEMP ]] || {
        _INLET_TIME=$SECONDS
        _debug "Reading Inlet Temp"
        _get_sensor_reading _INLET_TEMP "Inlet Temp"
    }
    printf -v "$1" '%s' "$_INLET_TEMP"
}

function _ipmitool_action() { # <args>...
  if [[ $DRYRUN ]]; then
    echo "[dry-run] ipmitool" "$@"
  else
    ipmitool "$@"
  fi
}

function _set_fan_speed() {
    # Sets the fan speed to the given percentage
    local _speed=$1

    # Ensure the speed is within the valid range
    if [[ $_speed -lt $MIN_SPEED ]]; then
        _speed=$MIN_SPEED
    elif [[ $_speed -gt $MAX_SPEED ]]; then
        _speed=$MAX_SPEED
    fi

    # Convert the speed to hex
    local _hex_speed
    printf -v _hex_speed "0x%x" "$_speed"

    # Set the fan speed
    _ipmitool_action raw 0x30 0x30 0x02 0xff "$_hex_speed" >&/dev/null
}

function _enable_manual_fan_control() {
    # Enables manual fan control
    _ipmitool_action raw 0x30 0x30 0x01 0x00 >&/dev/null
}

function _disable_manual_fan_control() {
    # Disables manual fan control
    _ipmitool_action raw 0x30 0x30 0x01 0x01 >&/dev/null
}

function _limit_speed() { # <var> <speed> <temp>
    local _speed=$2 _temp=$3
    # Calculates max speed based on <temp>
    local _t _i=0 _max=$MAX_SPEED
    for _t in "${TEMP_STEPS[@]}"; do
        (( _temp < _t )) && {
            _max=${MAX_PWM_STEPS[_i]}
            (( _i == 0 )) || {
                local _pt _pm
                _pt=${TEMP_STEPS[_i-1]}
                _pm=${MAX_PWM_STEPS[_i-1]}
                _max=$((((_temp-_pt)*100)*(_max-_pm)/(_t-_pt)/100+_pm))
            }
            break
        }
        ((_i++)) || :
    done
    _debug "Max Speed: $_max"
    if (( _speed < MIN_SPEED )); then
        _speed=$MIN_SPEED
    elif (( _speed > _max )); then
        _speed=$_max
    fi
    printf -v "$1" '%s' "$_speed"
}

function _calculate_fan_speed() {
    # Calculates the fan speed based on the target temperature and the actual temperature
    local _target_temp=$1 _pkg_temp=$2 _fan_speed=$3

    # Calculate the difference between the actual temperature and target
    local _temp_diff=$(( _pkg_temp - _target_temp ))
    local _temp_diff_abs=${_temp_diff#-}

    # Calculate the fan speed change based on the range of the temperature difference
    local -i _speed_factor=0
    if (( _temp_diff_abs > 32 )); then
        _speed_factor=200
    elif (( _temp_diff_abs > 16 )); then
        _speed_factor=137
    elif (( _temp_diff_abs > 8 )); then
        _speed_factor=87
    elif (( _temp_diff_abs > 4 )); then
        _speed_factor=50
    elif (( _temp_diff_abs > 2 )); then
        _speed_factor=25
    fi

    # Offset speed factor based on the temperature
    (( _pkg_temp > g_hysteresis_temp )) &&
        _speed_factor=$(( _speed_factor + 75 ))

    # Update hysteresis factor based on the package temperature compared to the hysteresis temperature
    local -i _hysteresis_factor=2
    # move faster at high temps
    (( _pkg_temp > g_hysteresis_temp && _temp_diff > 0 )) &&
        _hysteresis_factor=3

    # Calculate the speed change based on the speed factor and hysteresis factor, ensure the range
    local -i _speed_change
    _speed_change=$(( ( ( _speed_factor * _hysteresis_factor ) + 50 ) / 100 ))
    (( _speed_change > g_max_change )) && _speed_change=$g_max_change

    # Give the speed change a direction
    (( _temp_diff < 0 )) && _speed_change=$(( _speed_change * -1 ))

    # Ensure the fan speed is reduced if the package temperature at or below the target
    (( _temp_diff < 0 && _speed_change == 0 )) && _speed_change=-1

    # Calculate the new fan speed
    _fan_speed=$(( _fan_speed + _speed_change ))

    # Debugging
    [[ $DEBUG ]] && {
        echo "Temp Diff: $_temp_diff"
        echo "Speed Factor: $(echo "scale=2; $_speed_factor/100" | bc)"
        echo "Hysteresis Factor: $_hysteresis_factor"
    } >&2

    _limit_speed _fan_speed "$_fan_speed" "$_pkg_temp"

    echo "$_fan_speed"
}

_LOG_TIME=
function _log_data() {

    [[ $LOG || $DEBUG ]] || {
        # slow output if not logging
        _cache_timeout "$_LOG_TIME" || return 0
        _LOG_TIME=$SECONDS
    }
    # Logs the data to a file
    local _pkg_temp=$1
    local _inlet_temp=$2
    local _target_temp=$3
    local _fan_speed=$4

    # Log the data
    local _msg
    [[ $LOG ]] && {
        # add timestamp if logging
        local _t=$EPOCHSECONDS
        LC_ALL=C printf -v _msg "%d %(%c)T - " "$_t" "$_t"
    }

    _msg+="Package Temp: $_pkg_temp, "
    _msg+="Inlet Temp: $_inlet_temp, "
    _msg+="Target Temp: $_target_temp, "
    _msg+="Fan Speed: $_fan_speed [$MIN_SPEED - $MAX_SPEED]"

    echo "$_msg"
}

function _run_critical_event() {
    # Runs the critical event command
    eval "$CRITICAL_EVENT_COMMAND"
}

## Main
function _main() {
    [[ ${#TEMP_STEPS[*]} == "${#MAX_PWM_STEPS[*]}" ]] ||
        _die "MAX_STEPS and MAX_PWM_STEPS must be have the same length!"
 
    local critical_event_wait=0 # The time since the critical temperature was met
    # Int Rounding Support
    local g_rnd_bgn="scale=8; a=("
    local g_rnd_end=" + 0.5); scale=0; a/1"
    # cap fan speed change to 2%/sec
    local g_max_change=$((LOOP_DELAY * 2))

    # Enable manual fan control and set the initial fan speed
    _enable_manual_fan_control

    # Calculate the hysteresis temperature and round to the nearest integer
    local g_hysteresis_temp
    g_hysteresis_temp=$(echo "$g_rnd_bgn($PACKAGE_ALARM_TEMP - ($HYSTERESIS_OFFSET * $HYSTERESIS_MULTIPLIER))$g_rnd_end" | bc)

    # Main control loop
    local pkg_temp inlet_temp target_temp fan_speed new_fan_speed
    _get_pkg_temp pkg_temp

    _limit_speed fan_speed "$MAX_SPEED" "$pkg_temp"
    _set_fan_speed "$fan_speed"

    while true; do
        # Get the current temperatures
        _get_pkg_temp pkg_temp
        _get_inlet_temp inlet_temp

        # Calculate the target temperature
        target_temp=$TARGET_TEMP
        (( inlet_temp > target_temp )) &&
            target_temp=$((inlet_temp + HYSTERESIS_OFFSET))

        # Debugging
        [[ $DEBUG ]] && {
            echo "--- New check"
            echo "Start Fan Speed: $fan_speed"
            echo "Critical Wait: $critical_event_wait"
            echo "Package Temp: $pkg_temp"
            echo "Inlet Temp: $inlet_temp"
            echo "Target Temp: $target_temp"
            echo "Hysteresis Temp: $g_hysteresis_temp"
        } >&2

        # Check for critical temperature
        if (( pkg_temp >= CRITICAL_TEMP )); then
            critical_event_wait=$((critical_event_wait + LOOP_DELAY))
            (( critical_event_wait >= HYSTERESIS_WAIT )) && {
                _log_err "PANIC: temperature $pkg_temp above $CRITICAL_TEMP for more than $HYSTERESIS_WAIT"
                _run_critical_event
                exit 1
            }
        else
            critical_event_wait=0
        fi

        # Check for package alarm temperature
        if (( pkg_temp >= PACKAGE_ALARM_TEMP )); then
            _debug "Package temp $pkg_temp > $PACKAGE_ALARM_TEMP"
            new_fan_speed=$MAX_SPEED
        else
            new_fan_speed=$(_calculate_fan_speed "$target_temp" "$pkg_temp" "$fan_speed")
        fi
        _debug "New Fan Speed: $new_fan_speed"

        # Set the new fan speed if it has changed
        if (( new_fan_speed != fan_speed )); then
            fan_speed=$new_fan_speed
            _set_fan_speed "$fan_speed"
        fi

        # Log the data
        _log_data "$pkg_temp" "$inlet_temp" "$target_temp" "$fan_speed"

        # Sleep for the loop delay
        sleep "$LOOP_DELAY"
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    trap _exit_trap EXIT
    if [[ $LOG ]]; then
        _main | tee -a "$LOG"
    else
        _main
    fi
fi
