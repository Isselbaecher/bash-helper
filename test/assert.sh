#!/usr/bin/env bash

# Shared lightweight test assertions for this repository.
# Usage in test scripts:
#   source test/assert.sh
#   test_init
#   assert_eq "expected" "actual" "label"
#   assert_rc 1 "label" command args...
#   test_finish

tests_total=0
tests_failed=0

test_init() {
    tests_total=0
    tests_failed=0
}

assert_eq() {
    local expected="${1}"
    local actual="${2}"
    local label="${3}"

    tests_total=$(( tests_total + 1 ))
    if [[ "${actual}" == "${expected}" ]]; then
        printf 'PASS: %s\n' "${label}"
    else
        printf 'FAIL: %s (expected=%q actual=%q)\n' "${label}" "${expected}" "${actual}" >&2
        tests_failed=$(( tests_failed + 1 ))
    fi
}

assert_match() {
    local regex="${1}"
    local actual="${2}"
    local label="${3}"

    tests_total=$(( tests_total + 1 ))
    if [[ "${actual}" =~ ${regex} ]]; then
        printf 'PASS: %s\n' "${label}"
    else
        printf 'FAIL: %s (regex=%q actual=%q)\n' "${label}" "${regex}" "${actual}" >&2
        tests_failed=$(( tests_failed + 1 ))
    fi
}

assert_rc() {
    local expected_rc="${1}"
    local label="${2}"
    shift 2

    tests_total=$(( tests_total + 1 ))
    "$@" >/dev/null 2>&1
    local rc=$?

    if (( rc == expected_rc )); then
        printf 'PASS: %s\n' "${label}"
    else
        printf 'FAIL: %s (expected_rc=%d actual_rc=%d)\n' "${label}" "${expected_rc}" "${rc}" >&2
        tests_failed=$(( tests_failed + 1 ))
    fi
}

test_finish() {
    printf '\nSummary: %d total, %d failed\n' "${tests_total}" "${tests_failed}"
    (( tests_failed == 0 ))
}
