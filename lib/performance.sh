##################################################
# Bash 4.x performance helpers
#
# Runtime control:
#   BASH_HELPER_PERF_LEVEL=0  -> disabled
#   BASH_HELPER_PERF_LEVEL>=1 -> enabled (default: 1)
#
# Basic API:
#   perf_start_to <out_varname>
#   perf_stop_to <out_varname> <start_epoch_ms>
#   perf_report_header
#   perf_report_result <label> <iterations> <elapsed_ms> <target_ms>
#
# Immediate section timer:
#   perf_measure_live_reset
#   perf_measure_live [label]
#
# Buffered section timer:
#   perf_measure_to_report_reset
#   perf_measure_to_report <label> <iterations> <target_ms>
#   perf_measure_to_report
#   perf_report
#
# perf_measure_live behavior:
#   - First call starts measurement for the provided label.
#   - Next call prints duration of the previous label.
#   - Final call with no label flushes the previous section and stops.
# Example:
#   perf_measure_live "command1_name"
#   command1
#   perf_measure_live "command2_name"
#   command2
#   perf_measure_live
# Output:
#   command1_name ->  0s 123ms
#   command2_name ->  1s   5ms
##################################################

if ! declare -F bh_val_out_varname >/dev/null 2>&1; then
    _bh_perf_lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    # shellcheck disable=SC1091
    source "${_bh_perf_lib_dir}/validation.sh"
fi

_bh_perf_now_ns_to() {
    if (( $# != 1 )); then
        printf 'usage: _bh_perf_now_ns_to <out_varname>\n' >&2
        return 2
    fi

    local out_varname="${1}"
    local now_ns_value epoch_sec epoch_micro

    bh_val_out_varname "${out_varname}" '_bh_perf_now_ns_to' || return 2

    # Bash 5 fast path: EPOCHREALTIME avoids spawning external date.
    if [[ -n "${EPOCHREALTIME-}" ]]; then
        epoch_sec="${EPOCHREALTIME%.*}"
        epoch_micro="${EPOCHREALTIME#*.}"
        epoch_micro="${epoch_micro:0:6}"
        while (( ${#epoch_micro} < 6 )); do
            epoch_micro+="0"
        done
        now_ns_value=$(( epoch_sec * 1000000000 + 10#${epoch_micro} * 1000 ))
    # Fallback: GNU date nanoseconds.
    elif now_ns_value="$(date +%s%N 2>/dev/null)" && [[ ${now_ns_value} =~ ^[0-9]+$ ]]; then
        :
    # Last resort: second precision converted to nanoseconds.
    else
        now_ns_value="$(( $(date +%s) * 1000000000 ))"
    fi

    printf -v "${out_varname}" '%s' "${now_ns_value}"
}

##################################################
# perf_start_to <out_varname>
#
# Writes current epoch milliseconds to <out_varname>.
##################################################
perf_start_to() {
    if (( $# != 1 )); then
        printf 'usage: perf_start_to <out_varname>\n' >&2
        return 2
    fi

    local out_varname="${1}"
    local now_ns

    bh_val_out_varname "${out_varname}" 'perf_start_to' || return 2
    _bh_perf_now_ns_to now_ns || return

    printf -v "${out_varname}" '%s' "$(( now_ns / 1000000 ))"
}

##################################################
# perf_stop_to <out_varname> <start_epoch_ms>
#
# Writes elapsed milliseconds between now and <start_epoch_ms>
# to <out_varname>.
##################################################
perf_stop_to() {
    if (( $# != 2 )); then
        printf 'usage: perf_stop_to <out_varname> <start_epoch_ms>\n' >&2
        return 2
    fi

    local out_varname="${1}"
    local start_epoch_ms="${2}"
    local now_ns now_epoch_ms elapsed_ms_value

    bh_val_out_varname "${out_varname}" 'perf_stop_to' || return 2
    bh_val_int "${start_epoch_ms}" 'start_epoch_ms' || return 2
    _bh_perf_now_ns_to now_ns || return

    now_epoch_ms=$(( now_ns / 1000000 ))
    elapsed_ms_value=$(( now_epoch_ms - start_epoch_ms ))
    printf -v "${out_varname}" '%s' "${elapsed_ms_value}"
}

##################################################
# perf_report_result <label> <iterations> <elapsed_ms> <target_ms>
#
# Prints one formatted benchmark result line and marks status as
# OK if elapsed_ms <= target_ms, otherwise SLOW.
##################################################
perf_report_header() {
    printf '+--------------------------+--------+-------------+-------------+------+'"\n"
    printf '| %-24s | %6s | %11s | %11s | %-4s |\n' 'Case' 'N' 'Actual' 'Target' 'Stat'
    printf '+--------------------------+--------+-------------+-------------+------+'"\n"
}

perf_report_footer() {
    printf '+--------------------------+--------+-------------+-------------+------+'"\n"
}

perf_report_section_header() {
    if (( $# != 1 )); then
        printf 'usage: perf_report_section_header <title>\n' >&2
        return 2
    fi

    local title="${1}"
    local content_width=67
    local max_title_width=$(( content_width - 2 ))

    if (( ${#title} > max_title_width )); then
        title="${title:0:max_title_width}"
    fi

    printf '\n+======================================================================+\n'
    printf '| %-68s |\n' "${title}"
    printf '+======================================================================+\n'
}

perf_report_result() {
    if (( $# != 4 )); then
        printf 'usage: perf_report_result <label> <iterations> <elapsed_ms> <target_ms>\n' >&2
        return 2
    fi

    local label="${1}"
    local iterations="${2}"
    local elapsed_ms="${3}"
    local target_ms="${4}"
    local status='OK'

    bh_val_int "${iterations}" 'iterations' || return 2
    bh_val_int "${elapsed_ms}" 'elapsed_ms' || return 2
    bh_val_int "${target_ms}" 'target_ms' || return 2

    if (( elapsed_ms > target_ms )); then
        status='SLOW'
    fi

    printf '| %-24s | %6d | %8d ms | %8d ms | %-4s |\n' \
        "${label}" "${iterations}" "${elapsed_ms}" "${target_ms}" "${status}"
}

perf_measure_live_reset() {
    _bh_perf_live_started_ns=0
    _bh_perf_live_last_ns=0
    _bh_perf_live_last_label=""
}

perf_measure_live() {
    # Read feature flag from environment; default is enabled.
    local perf_level="${BASH_HELPER_PERF_LEVEL-1}"
    [[ "${perf_level}" =~ ^-?[0-9]+$ ]] || perf_level=1
    # Fast no-op path when profiling is disabled.
    (( perf_level > 0 )) || return 0

    # Lazy-init persistent state so sourcing this file has no side effects.
    if [[ -z "${_bh_perf_live_started_ns+set}" ]]; then
        _bh_perf_live_started_ns=0
        _bh_perf_live_last_ns=0
        _bh_perf_live_last_label=""
    fi

    local now_ns elapsed_ns elapsed_ms elapsed_sec elapsed_millis
    local next_label="${1-}"

    _bh_perf_now_ns_to now_ns || return

    # First call only sets the baseline, it does not print.
    if (( _bh_perf_live_started_ns == 0 )); then
        _bh_perf_live_started_ns=${now_ns}
        _bh_perf_live_last_ns=${now_ns}
        _bh_perf_live_last_label=${next_label}
        return 0
    fi

    # Print elapsed time for the previous label (if any).
    if [[ -n "${_bh_perf_live_last_label}" ]]; then
        elapsed_ns=$(( now_ns - _bh_perf_live_last_ns ))
        elapsed_ms=$(( elapsed_ns / 1000000 ))
        elapsed_sec=$(( elapsed_ms / 1000 ))
        elapsed_millis=$(( elapsed_ms % 1000 ))

        # Name: truncate to 24 chars; Seconds: 4 wide; Milliseconds: 5 wide
        printf '%-24.24s -> %4ds%5dms\n' "${_bh_perf_live_last_label}" "${elapsed_sec}" "${elapsed_millis}"
    fi

    # Shift window forward so next call prints this section.
    _bh_perf_live_last_ns=${now_ns}
    _bh_perf_live_last_label=${next_label}
}

perf_measure_to_report_reset() {
    _bh_perf_report_started=0
    _bh_perf_report_last_ns=0
    _bh_perf_report_last_label=''
    _bh_perf_report_last_iterations=0
    _bh_perf_report_last_target_ms=0
    _bh_perf_report_rows=()
}

perf_measure_to_report() {
    local perf_level="${BASH_HELPER_PERF_LEVEL-1}"
    [[ "${perf_level}" =~ ^-?[0-9]+$ ]] || perf_level=1
    (( perf_level > 0 )) || return 0

    if (( $# != 0 && $# != 3 )); then
        printf 'usage: perf_measure_to_report [<label> <iterations> <target_ms>]\n' >&2
        return 2
    fi

    if [[ -z "${_bh_perf_report_started+set}" ]]; then
        perf_measure_to_report_reset
    fi

    local now_ns elapsed_ns elapsed_ms
    local sep=$'\x1f'
    local next_label="${1-}"
    local next_iterations="${2-0}"
    local next_target_ms="${3-0}"

    if (( $# == 3 )); then
        bh_val_int "${next_iterations}" 'iterations' || return 2
        bh_val_int "${next_target_ms}" 'target_ms' || return 2
    fi

    _bh_perf_now_ns_to now_ns || return

    if (( _bh_perf_report_started == 1 )) && [[ -n "${_bh_perf_report_last_label}" ]]; then
        elapsed_ns=$(( now_ns - _bh_perf_report_last_ns ))
        elapsed_ms=$(( elapsed_ns / 1000000 ))
        _bh_perf_report_rows+=("${_bh_perf_report_last_label}${sep}${_bh_perf_report_last_iterations}${sep}${elapsed_ms}${sep}${_bh_perf_report_last_target_ms}")
    fi

    if (( $# == 0 )); then
        _bh_perf_report_started=0
        _bh_perf_report_last_ns=0
        _bh_perf_report_last_label=''
        _bh_perf_report_last_iterations=0
        _bh_perf_report_last_target_ms=0
        return 0
    fi

    _bh_perf_report_started=1
    _bh_perf_report_last_ns=${now_ns}
    _bh_perf_report_last_label="${next_label}"
    _bh_perf_report_last_iterations=${next_iterations}
    _bh_perf_report_last_target_ms=${next_target_ms}
}

perf_report() {
    if [[ -z "${_bh_perf_report_rows+set}" || ${#_bh_perf_report_rows[@]} -eq 0 ]]; then
        return 0
    fi

    local row label iterations elapsed_ms target_ms
    local sep=$'\x1f'

    perf_report_header
    for row in "${_bh_perf_report_rows[@]}"; do
        IFS="${sep}" read -r label iterations elapsed_ms target_ms <<< "${row}"
        perf_report_result "${label}" "${iterations}" "${elapsed_ms}" "${target_ms}"
    done
    perf_report_footer

    perf_measure_to_report_reset
}