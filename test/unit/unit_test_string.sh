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

    # str_normalize_whitespace_to behavior
    str_normalize_whitespace_to out $'  hello\t\tworld\nagain  '
    assert_eq 'hello world again' "${out}" 'str_normalize_whitespace_to collapses mixed whitespace'

    str_normalize_whitespace_to out $'\n\t  '
    assert_eq '' "${out}" 'str_normalize_whitespace_to returns empty on all-whitespace input'

    str_normalize_whitespace_to out 'already clean'
    assert_eq 'already clean' "${out}" 'str_normalize_whitespace_to keeps single spaces intact'

    assert_rc 2 'str_normalize_whitespace_to invalid output varname rejected' str_normalize_whitespace_to '1bad' 'x'
    assert_rc 2 'str_normalize_whitespace_to usage error on missing args' str_normalize_whitespace_to out

    # str_starts_with / str_ends_with / str_contains
    assert_rc 0 'str_starts_with true' str_starts_with 'prefix_value' 'prefix_'
    assert_rc 1 'str_starts_with false' str_starts_with 'prefix_value' 'value'

    assert_rc 0 'str_ends_with true' str_ends_with 'value_suffix' '_suffix'
    assert_rc 1 'str_ends_with false' str_ends_with 'value_suffix' 'value_'

    assert_rc 0 'str_contains true' str_contains 'alpha_beta_gamma' '_beta_'
    assert_rc 1 'str_contains false' str_contains 'alpha_beta_gamma' '_delta_'

    # str_strip_prefix_to
    str_strip_prefix_to out 'prefix_body' 'prefix_'
    assert_eq 'body' "${out}" 'str_strip_prefix_to removes matching prefix'

    str_strip_prefix_to out 'body' 'prefix_'
    assert_eq 'body' "${out}" 'str_strip_prefix_to leaves non-matching string unchanged'

    assert_rc 2 'str_strip_prefix_to invalid output varname rejected' str_strip_prefix_to '1bad' 'x' 'y'

    # str_strip_suffix_to
    str_strip_suffix_to out 'body_suffix' '_suffix'
    assert_eq 'body' "${out}" 'str_strip_suffix_to removes matching suffix'

    str_strip_suffix_to out 'body' '_suffix'
    assert_eq 'body' "${out}" 'str_strip_suffix_to leaves non-matching string unchanged'

    assert_rc 2 'str_strip_suffix_to invalid output varname rejected' str_strip_suffix_to '1bad' 'x' 'y'

    # str_basename_to
    str_basename_to out '/tmp/demo/file.txt'
    assert_eq 'file.txt' "${out}" 'str_basename_to extracts basename from path'

    str_basename_to out '/tmp/demo/'
    assert_eq 'demo' "${out}" 'str_basename_to handles trailing slash'

    str_basename_to out 'file.txt'
    assert_eq 'file.txt' "${out}" 'str_basename_to keeps plain name unchanged'

    assert_rc 2 'str_basename_to invalid output varname rejected' str_basename_to '1bad' 'x'

    # str_dirname_to
    str_dirname_to out '/tmp/demo/file.txt'
    assert_eq '/tmp/demo' "${out}" 'str_dirname_to extracts dirname from path'

    str_dirname_to out 'file.txt'
    assert_eq '.' "${out}" 'str_dirname_to returns dot when no slash exists'

    assert_rc 2 'str_dirname_to invalid output varname rejected' str_dirname_to '1bad' 'x'
}

test_init
run_tests
test_finish
