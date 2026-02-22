#!/usr/bin/env bash

set -u

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# shellcheck disable=SC1091
source "${repo_root}/lib/validation.sh"
# shellcheck disable=SC1091
source "${repo_root}/lib/performance.sh"

target_val_case_ms() {
    local label="${1}"
    local iterations="${2}"

    case "${label}:${iterations}" in
        val_var_ok:1) printf '%s' 18 ;;
        val_var_ok:10) printf '%s' 21 ;;
        val_var_ok:100) printf '%s' 47 ;;
        val_var_ok:1000) printf '%s' 281 ;;

        val_var_bad:1) printf '%s' 16 ;;
        val_var_bad:10) printf '%s' 20 ;;
        val_var_bad:100) printf '%s' 44 ;;
        val_var_bad:1000) printf '%s' 306 ;;

        val_int_ok:1) printf '%s' 20 ;;
        val_int_ok:10) printf '%s' 18 ;;
        val_int_ok:100) printf '%s' 26 ;;
        val_int_ok:1000) printf '%s' 116 ;;

        val_int_bad:1) printf '%s' 2 ;;
        val_int_bad:10) printf '%s' 3 ;;
        val_int_bad:100) printf '%s' 16 ;;
        val_int_bad:1000) printf '%s' 131 ;;

        *)
            printf 'target_val_case_ms: no explicit target for %s (n=%s)\n' "${label}" "${iterations}" >&2
            return 2
            ;;
    esac
}

run_validation_bench_group() {
    local iterations="${1}"
    local i
    local target_ms

    perf_report_section_header "validation benchmark: ${iterations} iterations"
    perf_measure_to_report_reset

    target_ms="$(target_val_case_ms val_var_ok "${iterations}")"
    perf_measure_to_report 'val_var_ok' "${iterations}" "${target_ms}"
    for (( i = 0; i < iterations; i++ )); do
        bh_val_out_varname 'valid_name_123' >/dev/null 2>&1
    done

    target_ms="$(target_val_case_ms val_var_bad "${iterations}")"
    perf_measure_to_report 'val_var_bad' "${iterations}" "${target_ms}"
    for (( i = 0; i < iterations; i++ )); do
        bh_val_out_varname '1bad-name' >/dev/null 2>&1 || true
    done

    target_ms="$(target_val_case_ms val_int_ok "${iterations}")"
    perf_measure_to_report 'val_int_ok' "${iterations}" "${target_ms}"
    for (( i = 0; i < iterations; i++ )); do
        bh_val_int '123456' >/dev/null 2>&1
    done

    target_ms="$(target_val_case_ms val_int_bad "${iterations}")"
    perf_measure_to_report 'val_int_bad' "${iterations}" "${target_ms}"
    for (( i = 0; i < iterations; i++ )); do
        bh_val_int '12.34' >/dev/null 2>&1 || true
    done

    perf_measure_to_report
    perf_report
}

run_validation_bench_group 1
run_validation_bench_group 10
run_validation_bench_group 100
run_validation_bench_group 1000
