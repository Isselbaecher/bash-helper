#!/usr/bin/env bash

set -u

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# shellcheck disable=SC1091
source "${repo_root}/test/assert.sh"
# shellcheck disable=SC1091
source "${repo_root}/lib/validation.sh"
# shellcheck disable=SC1091
source "${repo_root}/lib/file.sh"

run_tests() {
    local tmp_base lock_name lock_path tmp_dir out

    tmp_base="${TMPDIR:-/tmp}/bash_helper_test.$$.${RANDOM}"
    mkdir -p -- "${tmp_base}"

    lock_name='unit_test_file.lock'
    lock_path="${tmp_base}/${lock_name}"

    # Lock acquire success/failure
    assert_rc 0 'file_lock_acquire creates lockfile' file_lock_acquire "${lock_name}" "${tmp_base}"
    assert_match '^.+$' "${lock_path}" 'lock path non-empty helper check'
    assert_rc 1 'file_lock_acquire fails when lock exists' file_lock_acquire "${lock_name}" "${tmp_base}"

    # tmpdir create
    assert_rc 0 'file_tmpdir_create_to works' file_tmpdir_create_to out 'unit_tmp' "${tmp_base}"
    tests_total=$(( tests_total + 1 ))
    if [[ -d "${out}" ]]; then
        printf 'PASS: created tmpdir exists\n'
    else
        printf 'FAIL: created tmpdir exists\n' >&2
        tests_failed=$(( tests_failed + 1 ))
    fi

    # invalid args / validation
    assert_rc 2 'file_tmpdir_create_to invalid out var' file_tmpdir_create_to '1bad' 'unit_tmp' "${tmp_base}"
    assert_rc 2 'file_lock_acquire empty lock name' file_lock_acquire '' "${tmp_base}"
    assert_rc 1 'file_tmpdir_create_to missing base path' file_tmpdir_create_to out 'unit_tmp' "${tmp_base}/missing"

    # cleanup helper
    rm -rf -- "${tmp_base}"
}

test_init
run_tests
test_finish
