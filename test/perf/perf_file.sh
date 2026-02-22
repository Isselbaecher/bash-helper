#!/usr/bin/env bash

set -u

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# shellcheck disable=SC1091
source "${repo_root}/lib/validation.sh"
# shellcheck disable=SC1091
source "${repo_root}/lib/file.sh"
# shellcheck disable=SC1091
source "${repo_root}/lib/performance.sh"

target_file_case_ms() {
    local label="${1}"
    local iterations="${2}"

    case "${label}:${iterations}" in
        lock_acquire:1) printf '%s' 110 ;;
        lock_acquire:10) printf '%s' 180 ;;
        lock_acquire:100) printf '%s' 1725 ;;

        tmpdir_create:1) printf '%s' 30 ;;
        tmpdir_create:10) printf '%s' 330 ;;
        tmpdir_create:100) printf '%s' 3385 ;;

        *)
            printf 'target_file_case_ms: no explicit target for %s (n=%s)\n' "${label}" "${iterations}" >&2
            return 2
            ;;
    esac
}

run_file_bench_group() {
    local iterations="${1}"
    local i
    local tmp_base lock_name out
    local target_ms

    tmp_base="${TMPDIR:-/tmp}/bash_helper_perf_file.$$.${RANDOM}"
    mkdir -p -- "${tmp_base}"

    perf_report_section_header "file benchmark: ${iterations} iterations"
    perf_measure_to_report_reset

    target_ms="$(target_file_case_ms lock_acquire "${iterations}")"
    perf_measure_to_report 'lock_acquire' "${iterations}" "${target_ms}"
    for (( i = 0; i < iterations; i++ )); do
        printf -v lock_name 'perf_lock_%03d.lock' "${i}"
        file_lock_acquire "${lock_name}" "${tmp_base}" >/dev/null 2>&1 || true
    done

    target_ms="$(target_file_case_ms tmpdir_create "${iterations}")"
    perf_measure_to_report 'tmpdir_create' "${iterations}" "${target_ms}"
    for (( i = 0; i < iterations; i++ )); do
        file_tmpdir_create_to out "perf_tmp_${i}" "${tmp_base}" >/dev/null 2>&1 || true
    done

    perf_measure_to_report
    perf_report

    : "${out}" "${lock_name}"
    rm -rf -- "${tmp_base}"
}

run_file_bench_group 1
run_file_bench_group 10
run_file_bench_group 100
