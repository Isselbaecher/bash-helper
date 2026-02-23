#!/usr/bin/env bash

set -u

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# shellcheck disable=SC1091
source "${repo_root}/lib/logging.sh"
# shellcheck disable=SC1091
source "${repo_root}/lib/performance.sh"

target_log_case_ms() {
    local label="${1}"
    local iterations="${2}"

    case "${label}:${iterations}" in
        debug_filtered:1) printf '%s' 15 ;;
        debug_filtered:10) printf '%s' 20 ;;
        debug_filtered:100) printf '%s' 32 ;;
        debug_filtered:1000) printf '%s' 166 ;;

        info_emit:1) printf '%s' 17 ;;
        info_emit:10) printf '%s' 18 ;;
        info_emit:100) printf '%s' 41 ;;
        info_emit:1000) printf '%s' 266 ;;

        warn_emit:1) printf '%s' 20 ;;
        warn_emit:10) printf '%s' 24 ;;
        warn_emit:100) printf '%s' 45 ;;
        warn_emit:1000) printf '%s' 251 ;;

        ok_or_warn_ok:1) printf '%s' 18 ;;
        ok_or_warn_ok:10) printf '%s' 24 ;;
        ok_or_warn_ok:100) printf '%s' 65 ;;
        ok_or_warn_ok:1000) printf '%s' 420 ;;

        ok_or_warn_fail:1) printf '%s' 20 ;;
        ok_or_warn_fail:10) printf '%s' 24 ;;
        ok_or_warn_fail:100) printf '%s' 45 ;;
        ok_or_warn_fail:1000) printf '%s' 360 ;;

        ok_or_exit_ok:1) printf '%s' 18 ;;
        ok_or_exit_ok:10) printf '%s' 24 ;;
        ok_or_exit_ok:100) printf '%s' 65 ;;
        ok_or_exit_ok:1000) printf '%s' 420 ;;

        *)
            printf 'target_log_case_ms: no explicit target for %s (n=%s)\n' "${label}" "${iterations}" >&2
            return 2
            ;;
    esac
}

run_log_bench_group() {
    local iterations="${1}"
    local i
    local target_ms

    perf_report_section_header "logging benchmark: ${iterations} iterations"
    perf_measure_to_report_reset

    log_set_level ERROR
    target_ms="$(target_log_case_ms debug_filtered "${iterations}")"
    perf_measure_to_report 'debug_filtered' "${iterations}" "${target_ms}"
    for (( i = 0; i < iterations; i++ )); do
        log_debug 'this is filtered'
    done

    log_set_level INFO
    target_ms="$(target_log_case_ms info_emit "${iterations}")"
    perf_measure_to_report 'info_emit' "${iterations}" "${target_ms}"
    for (( i = 0; i < iterations; i++ )); do
        log_info "loop ${i}" >/dev/null
    done

    target_ms="$(target_log_case_ms warn_emit "${iterations}")"
    perf_measure_to_report 'warn_emit' "${iterations}" "${target_ms}"
    for (( i = 0; i < iterations; i++ )); do
        log_warn "loop ${i}" 2>/dev/null
    done

    log_set_level INFO
    target_ms="$(target_log_case_ms ok_or_warn_ok "${iterations}")"
    perf_measure_to_report 'ok_or_warn_ok' "${iterations}" "${target_ms}"
    for (( i = 0; i < iterations; i++ )); do
        log_ok_or_warn 0 "loop ${i}" >/dev/null
    done

    target_ms="$(target_log_case_ms ok_or_warn_fail "${iterations}")"
    perf_measure_to_report 'ok_or_warn_fail' "${iterations}" "${target_ms}"
    for (( i = 0; i < iterations; i++ )); do
        log_ok_or_warn 7 "loop ${i}" 2>/dev/null
    done

    target_ms="$(target_log_case_ms ok_or_exit_ok "${iterations}")"
    perf_measure_to_report 'ok_or_exit_ok' "${iterations}" "${target_ms}"
    for (( i = 0; i < iterations; i++ )); do
        log_ok_or_exit 0 "loop ${i}" >/dev/null
    done

    perf_measure_to_report
    perf_report
}

run_log_bench_group 1
run_log_bench_group 10
run_log_bench_group 100
run_log_bench_group 1000
