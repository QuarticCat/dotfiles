#!/usr/bin/zsh

# Ref: https://llvm.org/docs/Benchmarking.html

config=()

bench-start() {
    for file enter exit in $config; sudo tee $file <<< $enter > /dev/null
    echo '>>>>> BENCH START' >&2
}

bench-end() {
    for file enter exit in $config; sudo tee $file <<< $exit > /dev/null
    echo '>>>>> BENCH END' >&2
}

# =============================== Config Begin =============================== #

# ASLR
config+=(/proc/sys/kernel/randomize_va_space '0' '1')

# turbo boost
if [[ $(</sys/devices/system/cpu/cpu0/cpufreq/scaling_driver) == 'acpi-cpufreq' ]] {
    config+=(/sys/devices/system/cpu/cpufreq/boost '0' '1')  # AMD
} else {
    config+=(/sys/devices/system/cpu/intel_pstate/no_turbo '1' '0')  # Intel
}

# scaling governor
for i in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; {
    config+=($i 'performance' 'schedutil')
}

# TODO: consider disabling SMT

# ================================ Config End ================================ #

bench-start
trap 'bench-end' EXIT INT
$@
