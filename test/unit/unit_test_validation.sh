#!/usr/bin/env bash

set -u

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# shellcheck disable=SC1091
source "${repo_root}/test/assert.sh"
# shellcheck disable=SC1091
source "${repo_root}/lib/validation.sh"

run_tests() {
    local rc

    # bh_val_out_varname success cases
    assert_rc 0 'valid var: simple' bh_val_out_varname 'abc'
    assert_rc 0 'valid var: underscore+digits' bh_val_out_varname '_a1_b2'

    # bh_val_out_varname failure cases
    assert_rc 2 'invalid var: starts with digit' bh_val_out_varname '1abc'
    assert_rc 2 'invalid var: contains dash' bh_val_out_varname 'ab-c'
    assert_rc 2 'invalid var: empty' bh_val_out_varname ''
    assert_rc 2 'usage error: too many args' bh_val_out_varname a b c

    # bh_val_int success cases
    assert_rc 0 'valid int: zero' bh_val_int '0'
    assert_rc 0 'valid int: positive' bh_val_int '123'
    assert_rc 0 'valid int: negative' bh_val_int '-42'

    # bh_val_int failure cases
    assert_rc 2 'invalid int: empty' bh_val_int ''
    assert_rc 2 'invalid int: decimal' bh_val_int '1.2'
    assert_rc 2 'invalid int: alpha' bh_val_int 'abc'
    assert_rc 2 'usage error: too many args' bh_val_int 1 a b

    # bh_check_cmd
    assert_rc 0 'bh_check_cmd: existing commands' bh_check_cmd bash printf
    assert_rc 127 'bh_check_cmd: missing command returns 127' bh_check_cmd definitely_missing_command
    assert_rc 0 'bh_check_cmd: no args is success' bh_check_cmd

    # bh_confirm
    bh_confirm 'Continue?' <<< 'y'
    rc=$?
    assert_eq '0' "${rc}" 'bh_confirm accepts y'

    bh_confirm 'Continue?' <<< 'Yes'
    rc=$?
    assert_eq '0' "${rc}" 'bh_confirm accepts yes (case-insensitive)'

    bh_confirm 'Continue?' <<< 'n'
    rc=$?
    assert_eq '1' "${rc}" 'bh_confirm rejects n'

    bh_confirm 'Continue?' <<< ''
    rc=$?
    assert_eq '1' "${rc}" 'bh_confirm rejects empty input'
}

test_init
run_tests
test_finish
