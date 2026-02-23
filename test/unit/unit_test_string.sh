#!/usr/bin/env bash

set -u

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# shellcheck disable=SC1091
source "${repo_root}/test/assert.sh"
# shellcheck disable=SC1091
source "${repo_root}/lib/validation.sh"
# shellcheck disable=SC1091
source "${repo_root}/lib/string.sh"

run_tests() {
    local out

    # core HTML characters
    str_escape_html_to out "a&b<c>d\"e'f"
    assert_eq 'a&amp;b&lt;c&gt;d&quot;e&apos;f' "${out}" 'escapes core html chars'

    # german / special entities
    str_escape_html_to out 'ÄäÖöÜüß ©€¢£¥®™'
    assert_eq '&Auml;&auml;&Ouml;&ouml;&Uuml;&uuml;&szlig; &copy;&euro;&cent;&pound;&yen;&reg;&trade;' "${out}" 'escapes configured special chars'

    # already-safe string unchanged
    str_escape_html_to out 'plain_text_123'
    assert_eq 'plain_text_123' "${out}" 'plain string unchanged'

    # ampersand first to avoid double-encoding introduced entities
    str_escape_html_to out '&lt;'
    assert_eq '&amp;lt;' "${out}" 'ampersand escaped first'

    # validation / usage failures
    assert_rc 2 'invalid output varname rejected' str_escape_html_to '1bad' 'x'
    assert_rc 2 'usage error on missing args' str_escape_html_to out

    # str_trim_to behavior
    str_trim_to out $'  hello world  '
    assert_eq 'hello world' "${out}" 'str_trim_to trims leading/trailing spaces'

    str_trim_to out $'\t  hello\n'
    assert_eq 'hello' "${out}" 'str_trim_to trims tabs/newlines at edges'

    str_trim_to out '   '
    assert_eq '' "${out}" 'str_trim_to returns empty on all-whitespace input'

    str_trim_to out 'already_clean'
    assert_eq 'already_clean' "${out}" 'str_trim_to keeps clean input unchanged'

    assert_rc 2 'str_trim_to invalid output varname rejected' str_trim_to '1bad' 'x'
}

test_init
run_tests
test_finish
