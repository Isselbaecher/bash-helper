##################################################
# Bash 4.x section timer with fixed-width output:
# name (15 chars, left) seconds (4 chars, right) milliseconds (5 chars, right)
#
# Runtime control:
#   BASH_HELPER_PERF_LEVEL=0  -> disabled
#   BASH_HELPER_PERF_LEVEL>=1 -> enabled (default: 1)
#
# Optional:
#   perf_measure_reset         -> resets measurement state
#
# Behavior:
#   - First call starts measurement for the provided name.
#   - Next call prints duration of the previous named section.
#   - Final call with no name flushes the previous section and stops.
# Example:
#   perf_measure "command1_name"
#   command1
#   perf_measure "command2_name"
#   command2
#   perf_measure
# Output:
#   command1_name ->  0s 123ms
#   command2_name ->  1s   5ms
##################################################
perf_measure_reset() {
    # Global state used by perf_measure between calls.
    # Reset allows clean timing sessions in long-lived shells.
    _bh_perf_started_ns=0
    _bh_perf_last_ns=0
    _bh_perf_last_label=""
}

perf_measure() {
    # Read feature flag from environment; default is enabled.
    local perf_level="${BASH_HELPER_PERF_LEVEL-1}"
    [[ "${perf_level}" =~ ^-?[0-9]+$ ]] || perf_level=1
    # Fast no-op path when profiling is disabled.
    (( perf_level > 0 )) || return 0

    # Lazy-init persistent state so sourcing this file has no side effects.
    if [[ -z "${_bh_perf_started_ns+set}" ]]; then
        _bh_perf_started_ns=0
        _bh_perf_last_ns=0
        _bh_perf_last_label=""
    fi

    local now_ns elapsed_ns elapsed_ms elapsed_sec elapsed_millis
    local epoch_sec epoch_micro
    local next_label="${1-}"

    # Bash 5 fast path: EPOCHREALTIME avoids spawning external date.
    if [[ -n "${EPOCHREALTIME-}" ]]; then
        epoch_sec="${EPOCHREALTIME%.*}"
        epoch_micro="${EPOCHREALTIME#*.}"
        # Keep microseconds and right-pad if needed (for arithmetic safety).
        epoch_micro="${epoch_micro:0:6}"
        while (( ${#epoch_micro} < 6 )); do
            epoch_micro+="0"
        done
        # Convert seconds + microseconds to nanoseconds.
        now_ns=$(( epoch_sec * 1000000000 + 10#${epoch_micro} * 1000 ))
    # Fallback: GNU date nanoseconds.
    elif now_ns="$(date +%s%N 2>/dev/null)" && [[ "${now_ns}" =~ ^[0-9]+$ ]]; then
        :
    # Last resort: second precision converted to nanoseconds.
    else
        now_ns="$(( $(date +%s) * 1000000000 ))"
    fi

    # First call only sets the baseline, it does not print.
    if (( _bh_perf_started_ns == 0 )); then
        _bh_perf_started_ns=${now_ns}
        _bh_perf_last_ns=${now_ns}
        _bh_perf_last_label=${next_label}
        return 0
    fi

    # Print elapsed time for the previous label (if any).
    if [[ -n "${_bh_perf_last_label}" ]]; then
        elapsed_ns=$(( now_ns - _bh_perf_last_ns ))
        elapsed_ms=$(( elapsed_ns / 1000000 ))
        elapsed_sec=$(( elapsed_ms / 1000 ))
        elapsed_millis=$(( elapsed_ms % 1000 ))

        # Name: truncate to 15 chars; Seconds: 4 wide; Milliseconds: 5 wide
        printf '%-15.15s -> %4ds%5dms\n' "${_bh_perf_last_label}" "${elapsed_sec}" "${elapsed_millis}"
    fi

    # Shift window forward so next call prints this section.
    _bh_perf_last_ns=${now_ns}
    _bh_perf_last_label=${next_label}
}