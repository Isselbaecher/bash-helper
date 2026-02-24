#!/usr/bin/env bash

set -u

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# shellcheck disable=SC1091
source "${repo_root}/test/assert.sh"
# shellcheck disable=SC1091
source "${repo_root}/lib/validation.sh"

_test_bh_is_set_set_nonempty() {
    local _t_var='x'
    bh_is_set _t_var
}

_test_bh_is_set_set_empty() {
    local _t_var=''
    bh_is_set _t_var
}

_test_bh_is_set_unset() {
    unset _t_var
    bh_is_set _t_var
}

_test_bh_require_var_set_nonempty() {
    local _t_var='x'
    bh_require_var _t_var
}

_test_bh_require_var_set_empty() {
    local _t_var=''
    bh_require_var _t_var
}

_test_bh_require_var_unset() {
    unset _t_var
    bh_require_var _t_var
}

_test_bh_require_nonempty_var_set_nonempty() {
    local _t_var='x'
    bh_require_nonempty_var _t_var
}

_test_bh_require_nonempty_var_set_empty() {
    local _t_var=''
    bh_require_nonempty_var _t_var
}

_test_bh_require_nonempty_var_unset() {
    unset _t_var
    bh_require_nonempty_var _t_var
}

_test_val_tmp_dir=''
_test_val_tmp_file=''
_test_val_missing_path=''
_test_val_exec_path=''

_test_bh_require_file_ok() {
    bh_require_file "${_test_val_tmp_file}"
}

_test_bh_require_file_fail_dir() {
    bh_require_file "${_test_val_tmp_dir}"
}

_test_bh_require_dir_ok() {
    bh_require_dir "${_test_val_tmp_dir}"
}

_test_bh_require_dir_fail_file() {
    bh_require_dir "${_test_val_tmp_file}"
}

_test_bh_require_readable_ok() {
    bh_require_readable "${_test_val_tmp_file}"
}

_test_bh_require_readable_fail_missing() {
    bh_require_readable "${_test_val_missing_path}"
}

_test_bh_require_writable_ok() {
    bh_require_writable "${_test_val_tmp_file}"
}

_test_bh_require_writable_fail_missing() {
    bh_require_writable "${_test_val_missing_path}"
}

_test_bh_require_executable_ok() {
    bh_require_executable "${_test_val_exec_path}"
}

_test_bh_require_executable_fail_nonexec() {
    bh_require_executable "${_test_val_tmp_file}"
}

run_tests() {
    local rc

    _test_val_tmp_dir="${repo_root}/test/.tmp_validation_${$}"
    _test_val_tmp_file="${_test_val_tmp_dir}/sample.txt"
    _test_val_missing_path="${_test_val_tmp_dir}/missing"
    _test_val_exec_path="$(command -v bash)"

    mkdir -p "${_test_val_tmp_dir}"
    printf 'x\n' > "${_test_val_tmp_file}"
    chmod 0644 "${_test_val_tmp_file}" 2>/dev/null || true

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

    # bh_is_set
    assert_rc 0 'bh_is_set: set non-empty var' _test_bh_is_set_set_nonempty
    assert_rc 0 'bh_is_set: set empty var' _test_bh_is_set_set_empty
    assert_rc 1 'bh_is_set: unset var' _test_bh_is_set_unset
    assert_rc 2 'bh_is_set: invalid varname rejected' bh_is_set '1bad'
    assert_rc 2 'bh_is_set: usage error missing arg' bh_is_set

    # bh_require_var
    assert_rc 0 'bh_require_var: set non-empty var' _test_bh_require_var_set_nonempty
    assert_rc 0 'bh_require_var: set empty var allowed' _test_bh_require_var_set_empty
    assert_rc 2 'bh_require_var: unset var rejected' _test_bh_require_var_unset
    assert_rc 2 'bh_require_var: invalid varname rejected' bh_require_var '1bad'
    assert_rc 2 'bh_require_var: usage error missing arg' bh_require_var

    # bh_require_nonempty_var
    assert_rc 0 'bh_require_nonempty_var: set non-empty var' _test_bh_require_nonempty_var_set_nonempty
    assert_rc 2 'bh_require_nonempty_var: set empty var rejected' _test_bh_require_nonempty_var_set_empty
    assert_rc 2 'bh_require_nonempty_var: unset var rejected' _test_bh_require_nonempty_var_unset
    assert_rc 2 'bh_require_nonempty_var: invalid varname rejected' bh_require_nonempty_var '1bad'
    assert_rc 2 'bh_require_nonempty_var: usage error missing arg' bh_require_nonempty_var

    # bh_require_file / bh_require_dir
    assert_rc 0 'bh_require_file: existing file accepted' _test_bh_require_file_ok
    assert_rc 2 'bh_require_file: directory rejected' _test_bh_require_file_fail_dir
    assert_rc 2 'bh_require_file: usage error missing arg' bh_require_file

    assert_rc 0 'bh_require_dir: existing directory accepted' _test_bh_require_dir_ok
    assert_rc 2 'bh_require_dir: file rejected' _test_bh_require_dir_fail_file
    assert_rc 2 'bh_require_dir: usage error missing arg' bh_require_dir

    # bh_require_readable / bh_require_writable
    assert_rc 0 'bh_require_readable: readable path accepted' _test_bh_require_readable_ok
    assert_rc 2 'bh_require_readable: missing path rejected' _test_bh_require_readable_fail_missing
    assert_rc 2 'bh_require_readable: usage error missing arg' bh_require_readable

    assert_rc 0 'bh_require_writable: writable path accepted' _test_bh_require_writable_ok
    assert_rc 2 'bh_require_writable: missing path rejected' _test_bh_require_writable_fail_missing
    assert_rc 2 'bh_require_writable: usage error missing arg' bh_require_writable

    # bh_require_executable
    assert_rc 0 'bh_require_executable: executable path accepted' _test_bh_require_executable_ok
    assert_rc 2 'bh_require_executable: non-executable file rejected' _test_bh_require_executable_fail_nonexec
    assert_rc 2 'bh_require_executable: usage error missing arg' bh_require_executable

    rm -rf "${_test_val_tmp_dir}"
}

test_init
run_tests
test_finish
