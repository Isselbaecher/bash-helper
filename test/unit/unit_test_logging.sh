#!/usr/bin/env bash

set -u

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# shellcheck disable=SC1091
source "${repo_root}/test/assert.sh"
# shellcheck disable=SC1091
source "${repo_root}/lib/logging.sh"

run_tests() {
    local out err

    # level config and validation
    assert_rc 0 'log_set_level accepts INFO' log_set_level INFO
    assert_rc 2 'log_set_level rejects invalid level' log_set_level VERBOSE

    # INFO -> stdout
    out="$(log_info 'hello info')"
    assert_match '^.+ \| INFO +\| pid=[0-9]+ \| hello info$' "${out}" 'log_info format on stdout'

    # WARN -> stderr
    err="$(log_warn 'hello warn' 2>&1 >/dev/null)"
    assert_match '^.+ \| WARN +\| pid=[0-9]+ \| hello warn$' "${err}" 'log_warn format on stderr'

    # ERROR -> stderr
    err="$(log_error 'hello error' 2>&1 >/dev/null)"
    assert_match '^.+ \| ERROR \| pid=[0-9]+ \| hello error$' "${err}" 'log_error format on stderr'

    # Filtering: INFO suppressed at WARN level
    log_set_level WARN
    out="$(log_info 'should be suppressed')"
    assert_eq '' "${out}" 'log_info filtered out at WARN level'

    # WARN still visible at WARN level
    err="$(log_warn 'visible warn' 2>&1 >/dev/null)"
    assert_match '^.+ \| WARN +\| pid=[0-9]+ \| visible warn$' "${err}" 'log_warn visible at WARN level'

    # Invalid level in log_msg
    assert_rc 2 'log_msg rejects invalid level' log_msg BAD 'x'

    # Restore default for caller shell session
    log_set_level INFO
}

test_init
run_tests
test_finish
