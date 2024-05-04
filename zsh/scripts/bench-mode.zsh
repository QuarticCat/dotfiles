#!/usr/bin/zsh

# Ref: https://llvm.org/docs/Benchmarking.html

files=()
on_vals=()
off_vals=()

set-file() {
    files+=($1)
    on_vals+=($2)
    off_vals+=($3)
}

bench-start() {
    for i in {1..$#files}; sudo tee $files[i] <<< $on_vals[i] > /dev/null
    echo '>>>>> BENCH START' >&2
}

bench-end() {
    for i in {1..$#files}; sudo tee $files[i] <<< $off_vals[i] > /dev/null
    echo '>>>>> BENCH END' >&2
}

# =============================== Config Begin =============================== #

# ASLR
set-file /proc/sys/kernel/randomize_va_space '0' '1'

# turbo boost
if [[ $(</sys/devices/system/cpu/cpu0/cpufreq/scaling_driver) == 'acpi-cpufreq' ]] {
    set-file /sys/devices/system/cpu/cpufreq/boost '0' '1'  # AMD
} else {
    set-file /sys/devices/system/cpu/intel_pstate/no_turbo '1' '0'  # Intel
}

# scaling governor
for i in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; {
    set-file $i 'performance' 'schedutil'
}

# TODO: consider disabling SMT

# ================================ Config End ================================ #

bench-start
trap 'bench-end' EXIT INT
$@
