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

        val_int_bad:1) printf '%s' 20 ;;
        val_int_bad:10) printf '%s' 20 ;;
        val_int_bad:100) printf '%s' 30 ;;
        val_int_bad:1000) printf '%s' 131 ;;

        check_cmd_ok:1) printf '%s' 25 ;;
        check_cmd_ok:10) printf '%s' 30 ;;
        check_cmd_ok:100) printf '%s' 110 ;;
        check_cmd_ok:1000) printf '%s' 950 ;;

        check_cmd_bad:1) printf '%s' 30 ;;
        check_cmd_bad:10) printf '%s' 120 ;;
        check_cmd_bad:100) printf '%s' 900 ;;
        check_cmd_bad:1000) printf '%s' 8000 ;;

        confirm_yes:1) printf '%s' 20 ;;
        confirm_yes:10) printf '%s' 35 ;;
        confirm_yes:100) printf '%s' 170 ;;
        confirm_yes:1000) printf '%s' 1450 ;;

        confirm_no:1) printf '%s' 20 ;;
        confirm_no:10) printf '%s' 35 ;;
        confirm_no:100) printf '%s' 170 ;;
        confirm_no:1000) printf '%s' 1450 ;;

        is_set_hit:1) printf '%s' 20 ;;
        is_set_hit:10) printf '%s' 25 ;;
        is_set_hit:100) printf '%s' 45 ;;
        is_set_hit:1000) printf '%s' 280 ;;

        is_set_miss:1) printf '%s' 20 ;;
        is_set_miss:10) printf '%s' 25 ;;
        is_set_miss:100) printf '%s' 45 ;;
        is_set_miss:1000) printf '%s' 280 ;;

        require_var_hit:1) printf '%s' 20 ;;
        require_var_hit:10) printf '%s' 30 ;;
        require_var_hit:100) printf '%s' 75 ;;
        require_var_hit:1000) printf '%s' 500 ;;

        require_nonempty_hit:1) printf '%s' 20 ;;
        require_nonempty_hit:10) printf '%s' 30 ;;
        require_nonempty_hit:100) printf '%s' 75 ;;
        require_nonempty_hit:1000) printf '%s' 500 ;;

        require_nonempty_miss:1) printf '%s' 30 ;;
        require_nonempty_miss:10) printf '%s' 45 ;;
        require_nonempty_miss:100) printf '%s' 200 ;;
        require_nonempty_miss:1000) printf '%s' 1800 ;;

        require_file_hit:1) printf '%s' 25 ;;
        require_file_hit:10) printf '%s' 30 ;;
        require_file_hit:100) printf '%s' 80 ;;
        require_file_hit:1000) printf '%s' 550 ;;

        require_file_miss:1) printf '%s' 30 ;;
        require_file_miss:10) printf '%s' 45 ;;
        require_file_miss:100) printf '%s' 220 ;;
        require_file_miss:1000) printf '%s' 2000 ;;

        require_dir_hit:1) printf '%s' 25 ;;
        require_dir_hit:10) printf '%s' 30 ;;
        require_dir_hit:100) printf '%s' 80 ;;
        require_dir_hit:1000) printf '%s' 550 ;;

        require_readable_hit:1) printf '%s' 25 ;;
        require_readable_hit:10) printf '%s' 30 ;;
        require_readable_hit:100) printf '%s' 80 ;;
        require_readable_hit:1000) printf '%s' 550 ;;

        require_writable_hit:1) printf '%s' 25 ;;
        require_writable_hit:10) printf '%s' 30 ;;
        require_writable_hit:100) printf '%s' 80 ;;
        require_writable_hit:1000) printf '%s' 550 ;;

        require_executable_hit:1) printf '%s' 25 ;;
        require_executable_hit:10) printf '%s' 30 ;;
        require_executable_hit:100) printf '%s' 80 ;;
        require_executable_hit:1000) printf '%s' 550 ;;

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
    # shellcheck disable=SC2034
    local set_var='value'
    # shellcheck disable=SC2034
    local empty_var=''
    local tmp_dir="${repo_root}/test/.tmp_val_perf_${$}"
    local tmp_file="${tmp_dir}/sample.txt"
    local missing_path="${tmp_dir}/missing"
    local exec_path

    exec_path="$(command -v bash)"
    mkdir -p "${tmp_dir}"
    printf 'x\n' > "${tmp_file}"
    chmod 0644 "${tmp_file}" 2>/dev/null || true

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

    target_ms="$(target_val_case_ms check_cmd_ok "${iterations}")"
    perf_measure_to_report 'check_cmd_ok' "${iterations}" "${target_ms}"
    for (( i = 0; i < iterations; i++ )); do
        bh_check_cmd bash printf >/dev/null 2>&1
    done

    target_ms="$(target_val_case_ms check_cmd_bad "${iterations}")"
    perf_measure_to_report 'check_cmd_bad' "${iterations}" "${target_ms}"
    for (( i = 0; i < iterations; i++ )); do
        bh_check_cmd definitely_missing_command >/dev/null 2>&1 || true
    done

    target_ms="$(target_val_case_ms confirm_yes "${iterations}")"
    perf_measure_to_report 'confirm_yes' "${iterations}" "${target_ms}"
    for (( i = 0; i < iterations; i++ )); do
        bh_confirm '' <<< 'y' >/dev/null 2>&1
    done

    target_ms="$(target_val_case_ms confirm_no "${iterations}")"
    perf_measure_to_report 'confirm_no' "${iterations}" "${target_ms}"
    for (( i = 0; i < iterations; i++ )); do
        bh_confirm '' <<< 'n' >/dev/null 2>&1 || true
    done

    target_ms="$(target_val_case_ms is_set_hit "${iterations}")"
    perf_measure_to_report 'is_set_hit' "${iterations}" "${target_ms}"
    for (( i = 0; i < iterations; i++ )); do
        bh_is_set set_var >/dev/null 2>&1
    done

    target_ms="$(target_val_case_ms is_set_miss "${iterations}")"
    perf_measure_to_report 'is_set_miss' "${iterations}" "${target_ms}"
    for (( i = 0; i < iterations; i++ )); do
        bh_is_set unset_var >/dev/null 2>&1 || true
    done

    target_ms="$(target_val_case_ms require_var_hit "${iterations}")"
    perf_measure_to_report 'require_var_hit' "${iterations}" "${target_ms}"
    for (( i = 0; i < iterations; i++ )); do
        bh_require_var set_var >/dev/null 2>&1
    done

    target_ms="$(target_val_case_ms require_nonempty_hit "${iterations}")"
    perf_measure_to_report 'require_nonempty_hit' "${iterations}" "${target_ms}"
    for (( i = 0; i < iterations; i++ )); do
        bh_require_nonempty_var set_var >/dev/null 2>&1
    done

    target_ms="$(target_val_case_ms require_nonempty_miss "${iterations}")"
    perf_measure_to_report 'require_nonempty_miss' "${iterations}" "${target_ms}"
    for (( i = 0; i < iterations; i++ )); do
        bh_require_nonempty_var empty_var >/dev/null 2>&1 || true
    done

    target_ms="$(target_val_case_ms require_file_hit "${iterations}")"
    perf_measure_to_report 'require_file_hit' "${iterations}" "${target_ms}"
    for (( i = 0; i < iterations; i++ )); do
        bh_require_file "${tmp_file}" >/dev/null 2>&1
    done

    target_ms="$(target_val_case_ms require_file_miss "${iterations}")"
    perf_measure_to_report 'require_file_miss' "${iterations}" "${target_ms}"
    for (( i = 0; i < iterations; i++ )); do
        bh_require_file "${missing_path}" >/dev/null 2>&1 || true
    done

    target_ms="$(target_val_case_ms require_dir_hit "${iterations}")"
    perf_measure_to_report 'require_dir_hit' "${iterations}" "${target_ms}"
    for (( i = 0; i < iterations; i++ )); do
        bh_require_dir "${tmp_dir}" >/dev/null 2>&1
    done

    target_ms="$(target_val_case_ms require_readable_hit "${iterations}")"
    perf_measure_to_report 'require_readable_hit' "${iterations}" "${target_ms}"
    for (( i = 0; i < iterations; i++ )); do
        bh_require_readable "${tmp_file}" >/dev/null 2>&1
    done

    target_ms="$(target_val_case_ms require_writable_hit "${iterations}")"
    perf_measure_to_report 'require_writable_hit' "${iterations}" "${target_ms}"
    for (( i = 0; i < iterations; i++ )); do
        bh_require_writable "${tmp_file}" >/dev/null 2>&1
    done

    target_ms="$(target_val_case_ms require_executable_hit "${iterations}")"
    perf_measure_to_report 'require_executable_hit' "${iterations}" "${target_ms}"
    for (( i = 0; i < iterations; i++ )); do
        bh_require_executable "${exec_path}" >/dev/null 2>&1
    done

    perf_measure_to_report
    perf_report

    rm -rf "${tmp_dir}"
}

run_validation_bench_group 1
run_validation_bench_group 10
run_validation_bench_group 100
run_validation_bench_group 1000
