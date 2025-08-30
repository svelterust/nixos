#!/usr/bin/env bash

current_governor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)

if [[ "$current_governor" == "performance" ]]; then
    # Switch to power save
    echo powersave | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor > /dev/null
    echo power | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference > /dev/null 2>&1 || true
    echo 0 | sudo tee /sys/devices/system/cpu/intel_pstate/min_perf_pct > /dev/null 2>&1 || true
    echo 75 | sudo tee /sys/devices/system/cpu/intel_pstate/max_perf_pct > /dev/null 2>&1 || true
    echo auto | sudo tee /sys/class/drm/card*/device/power/control > /dev/null 2>&1 || true
    notify-send "Power Mode" "Power save enabled"
else
    # Switch to performance
    echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor > /dev/null
    echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference > /dev/null 2>&1 || true
    echo 25 | sudo tee /sys/devices/system/cpu/intel_pstate/min_perf_pct > /dev/null 2>&1 || true
    echo 100 | sudo tee /sys/devices/system/cpu/intel_pstate/max_perf_pct > /dev/null 2>&1 || true
    echo on | sudo tee /sys/class/drm/card*/device/power/control > /dev/null 2>&1 || true
    notify-send "Power Mode" "Performance enabled"
fi
