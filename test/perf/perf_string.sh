#!/usr/bin/env bash

set -u

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# shellcheck disable=SC1091
source "${repo_root}/lib/validation.sh"
# shellcheck disable=SC1091
source "${repo_root}/lib/string.sh"
# shellcheck disable=SC1091
source "${repo_root}/lib/performance.sh"

target_str_case_ms() {
    local label="${1}"
    local iterations="${2}"

    case "${label}:${iterations}" in
        escape_clean:1) printf '%s' 21 ;;
        escape_clean:10) printf '%s' 23 ;;
        escape_clean:100) printf '%s' 57 ;;
        escape_clean:1000) printf '%s' 408 ;;

        escape_html:1) printf '%s' 23 ;;
        escape_html:10) printf '%s' 28 ;;
        escape_html:100) printf '%s' 63 ;;
        escape_html:1000) printf '%s' 476 ;;

        escape_special:1) printf '%s' 20 ;;
        escape_special:10) printf '%s' 24 ;;
        escape_special:100) printf '%s' 62 ;;
        escape_special:1000) printf '%s' 537 ;;

        trim_clean:1) printf '%s' 18 ;;
        trim_clean:10) printf '%s' 20 ;;
        trim_clean:100) printf '%s' 50 ;;
        trim_clean:1000) printf '%s' 320 ;;

        trim_spaced:1) printf '%s' 18 ;;
        trim_spaced:10) printf '%s' 20 ;;
        trim_spaced:100) printf '%s' 40 ;;
        trim_spaced:1000) printf '%s' 300 ;;

        normalize_clean:1) printf '%s' 18 ;;
        normalize_clean:10) printf '%s' 20 ;;
        normalize_clean:100) printf '%s' 50 ;;
        normalize_clean:1000) printf '%s' 380 ;;

        normalize_messy:1) printf '%s' 18 ;;
        normalize_messy:10) printf '%s' 20 ;;
        normalize_messy:100) printf '%s' 55 ;;
        normalize_messy:1000) printf '%s' 420 ;;

        starts_with_hit:1) printf '%s' 18 ;;
        starts_with_hit:10) printf '%s' 18 ;;
        starts_with_hit:100) printf '%s' 30 ;;
        starts_with_hit:1000) printf '%s' 150 ;;

        contains_hit:1) printf '%s' 18 ;;
        contains_hit:10) printf '%s' 18 ;;
        contains_hit:100) printf '%s' 30 ;;
        contains_hit:1000) printf '%s' 170 ;;

        strip_prefix_hit:1) printf '%s' 18 ;;
        strip_prefix_hit:10) printf '%s' 20 ;;
        strip_prefix_hit:100) printf '%s' 45 ;;
        strip_prefix_hit:1000) printf '%s' 320 ;;

        strip_suffix_hit:1) printf '%s' 18 ;;
        strip_suffix_hit:10) printf '%s' 20 ;;
        strip_suffix_hit:100) printf '%s' 45 ;;
        strip_suffix_hit:1000) printf '%s' 320 ;;

        basename_path:1) printf '%s' 18 ;;
        basename_path:10) printf '%s' 20 ;;
        basename_path:100) printf '%s' 45 ;;
        basename_path:1000) printf '%s' 280 ;;

        dirname_path:1) printf '%s' 18 ;;
        dirname_path:10) printf '%s' 20 ;;
        dirname_path:100) printf '%s' 45 ;;
        dirname_path:1000) printf '%s' 280 ;;

        *)
            printf 'target_str_case_ms: no explicit target for %s (n=%s)\n' "${label}" "${iterations}" >&2
            return 2
            ;;
    esac
}

run_str_bench_group() {
    local iterations="${1}"
    local i
    local out
    local target_ms

    perf_report_section_header "string benchmark: ${iterations} iterations"
    perf_measure_to_report_reset

    target_ms="$(target_str_case_ms escape_clean "${iterations}")"
    perf_measure_to_report 'escape_clean' "${iterations}" "${target_ms}"
    for (( i = 0; i < iterations; i++ )); do
        str_escape_html_to out 'plain_text_123'
    done

    target_ms="$(target_str_case_ms escape_html "${iterations}")"
    perf_measure_to_report 'escape_html' "${iterations}" "${target_ms}"
    for (( i = 0; i < iterations; i++ )); do
        str_escape_html_to out "a&b<c>d\"e'f"
    done

    target_ms="$(target_str_case_ms escape_special "${iterations}")"
    perf_measure_to_report 'escape_special' "${iterations}" "${target_ms}"
    for (( i = 0; i < iterations; i++ )); do
        str_escape_html_to out 'ÄäÖöÜüß ©€¢£¥®™'
    done

    target_ms="$(target_str_case_ms trim_clean "${iterations}")"
    perf_measure_to_report 'trim_clean' "${iterations}" "${target_ms}"
    for (( i = 0; i < iterations; i++ )); do
        str_trim_to out 'plain_text_123'
    done

    target_ms="$(target_str_case_ms trim_spaced "${iterations}")"
    perf_measure_to_report 'trim_spaced' "${iterations}" "${target_ms}"
    for (( i = 0; i < iterations; i++ )); do
        str_trim_to out $'  \t trim me \n  '
    done

    target_ms="$(target_str_case_ms normalize_clean "${iterations}")"
    perf_measure_to_report 'normalize_clean' "${iterations}" "${target_ms}"
    for (( i = 0; i < iterations; i++ )); do
        str_normalize_whitespace_to out 'already clean'
    done

    target_ms="$(target_str_case_ms normalize_messy "${iterations}")"
    perf_measure_to_report 'normalize_messy' "${iterations}" "${target_ms}"
    for (( i = 0; i < iterations; i++ )); do
        str_normalize_whitespace_to out $'  very\t\t messy\n text  '
    done

    target_ms="$(target_str_case_ms starts_with_hit "${iterations}")"
    perf_measure_to_report 'starts_with_hit' "${iterations}" "${target_ms}"
    for (( i = 0; i < iterations; i++ )); do
        str_starts_with 'prefix_value' 'prefix_' >/dev/null
    done

    target_ms="$(target_str_case_ms contains_hit "${iterations}")"
    perf_measure_to_report 'contains_hit' "${iterations}" "${target_ms}"
    for (( i = 0; i < iterations; i++ )); do
        str_contains 'alpha_beta_gamma' '_beta_' >/dev/null
    done

    target_ms="$(target_str_case_ms strip_prefix_hit "${iterations}")"
    perf_measure_to_report 'strip_prefix_hit' "${iterations}" "${target_ms}"
    for (( i = 0; i < iterations; i++ )); do
        str_strip_prefix_to out 'prefix_payload' 'prefix_'
    done

    target_ms="$(target_str_case_ms strip_suffix_hit "${iterations}")"
    perf_measure_to_report 'strip_suffix_hit' "${iterations}" "${target_ms}"
    for (( i = 0; i < iterations; i++ )); do
        str_strip_suffix_to out 'payload_suffix' '_suffix'
    done

    target_ms="$(target_str_case_ms basename_path "${iterations}")"
    perf_measure_to_report 'basename_path' "${iterations}" "${target_ms}"
    for (( i = 0; i < iterations; i++ )); do
        str_basename_to out '/tmp/demo/file.txt'
    done

    target_ms="$(target_str_case_ms dirname_path "${iterations}")"
    perf_measure_to_report 'dirname_path' "${iterations}" "${target_ms}"
    for (( i = 0; i < iterations; i++ )); do
        str_dirname_to out '/tmp/demo/file.txt'
    done

    perf_measure_to_report
    perf_report

    : "${out}"
}

run_str_bench_group 1
run_str_bench_group 10
run_str_bench_group 100
run_str_bench_group 1000
