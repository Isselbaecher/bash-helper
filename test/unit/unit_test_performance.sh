#!/usr/bin/env bash

set -u

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# shellcheck disable=SC1091
source "${repo_root}/test/assert.sh"
# shellcheck disable=SC1091
source "${repo_root}/lib/validation.sh"
# shellcheck disable=SC1091
source "${repo_root}/lib/performance.sh"

run_tests() {
    local start_ms elapsed_ms output

    # perf_start_to / perf_stop_to basics
    assert_rc 0 'perf_start_to accepts valid out var' perf_start_to start_ms
    assert_match '^[0-9]+$' "${start_ms}" 'perf_start_to returns numeric epoch ms'

    perf_start_to start_ms
    for _ in {1..2000}; do :; done
    perf_stop_to elapsed_ms "${start_ms}"
    assert_match '^-?[0-9]+$' "${elapsed_ms}" 'perf_stop_to returns numeric diff'

    # usage/validation errors
    assert_rc 2 'perf_start_to usage error' perf_start_to
    assert_rc 2 'perf_start_to invalid out var' perf_start_to '1bad'
    assert_rc 2 'perf_stop_to usage error' perf_stop_to elapsed_ms
    assert_rc 2 'perf_stop_to invalid out var' perf_stop_to '1bad' 123
    assert_rc 2 'perf_stop_to invalid start ms' perf_stop_to elapsed_ms nope

    # report formatting helpers
    output="$(perf_report_header)"
    assert_match 'Case[[:space:]]+\|[[:space:]]+N[[:space:]]+\|[[:space:]]+Actual[[:space:]]+\|[[:space:]]+Target[[:space:]]+\|[[:space:]]+Stat' "${output}" 'perf_report_header prints table header'

    output="$(perf_report_result sample_case 10 25 30)"
    assert_match '^\| sample_case[[:space:]]+\|[[:space:]]+10[[:space:]]+\|[[:space:]]+25 ms[[:space:]]+\|[[:space:]]+30 ms[[:space:]]+\| OK[[:space:]]+\|$' "${output}" 'perf_report_result prints OK row'

    output="$(perf_report_result sample_case 10 35 30)"
    assert_match '^\| sample_case[[:space:]]+\|[[:space:]]+10[[:space:]]+\|[[:space:]]+35 ms[[:space:]]+\|[[:space:]]+30 ms[[:space:]]+\| SLOW[[:space:]]+\|$' "${output}" 'perf_report_result prints SLOW row'

    assert_rc 2 'perf_report_result usage error' perf_report_result a b c

    # live mode API
    perf_measure_live_reset
    output="$(
        perf_measure_live phase_a
        for _ in {1..1000}; do :; done
        perf_measure_live phase_b
        for _ in {1..1000}; do :; done
        perf_measure_live
    )"
    assert_match 'phase_a[[:space:]]+->[[:space:]]+[0-9]+s[[:space:]]+[0-9]+ms' "${output}" 'perf_measure_live prints previous phase timing'

    # buffered mode API + final report
    perf_measure_to_report_reset
    output="$(
        perf_measure_to_report alpha 10 100
        for _ in {1..1000}; do :; done
        perf_measure_to_report beta 10 100
        for _ in {1..1000}; do :; done
        perf_measure_to_report
        perf_report
    )"

    assert_match 'Case[[:space:]]+\|[[:space:]]+N[[:space:]]+\|[[:space:]]+Actual[[:space:]]+\|[[:space:]]+Target[[:space:]]+\|[[:space:]]+Stat' "${output}" 'perf_report prints header from buffered rows'
    assert_match 'alpha' "${output}" 'perf_report contains first buffered row'
    assert_match 'beta' "${output}" 'perf_report contains second buffered row'

    # report reset after print
    output="$(perf_report)"
    assert_eq '' "${output}" 'perf_report clears buffered rows after print'

    # buffered mode argument validation
    assert_rc 2 'perf_measure_to_report usage error' perf_measure_to_report only two
    assert_rc 2 'perf_measure_to_report invalid iterations' perf_measure_to_report x nope 10
    assert_rc 2 'perf_measure_to_report invalid target' perf_measure_to_report x 1 nope
}

test_init
run_tests
test_finish
