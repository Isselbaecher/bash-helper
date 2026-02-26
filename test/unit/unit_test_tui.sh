#!/usr/bin/env bash

set -u

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# shellcheck disable=SC1091
source "${repo_root}/test/assert.sh"
# shellcheck disable=SC1091
source "${repo_root}/lib/validation.sh"
# shellcheck disable=SC1091
source "${repo_root}/lib/tui.sh"

run_tests() {
	local err
	local selected=''
	local err_file
	err_file="$(mktemp)"

	selected=''
	tui_select_list_to selected 'Pick one:' 'Alpha' 'Beta' 'Gamma' <<< '2' 2>"${err_file}" >/dev/null
	err="$(<"${err_file}")"
	assert_match '\+-- Pick one:' "${err}" 'prints pretty menu header'
	assert_match 'Pick one:' "${err}" 'prints prompt header'
	assert_match '1\) Alpha' "${err}" 'prints numbered options'
	assert_match 'Enter choice \[1-3\]:' "${err}" 'prints selection prompt'
	assert_match 'OK: Selected: Beta' "${err}" 'prints chosen value after selection'
	assert_eq 'Beta' "${selected}" 'assigns selected option to output variable'

	selected=''
	tui_select_list_to selected 'Pick one:' 'Alpha' 'Beta' 'Gamma' <<< $'x\n3' 2>"${err_file}" >/dev/null
	err="$(<"${err_file}")"
	assert_match 'ERROR: Invalid selection:' "${err}" 'prints validation error for invalid selection'
	assert_match 'OK: Selected: Gamma' "${err}" 'prints chosen value after retry success'
	assert_eq 'Gamma' "${selected}" 're-prompts until valid selection'

	assert_rc 2 'rejects invalid output varname' tui_select_list_to '1bad' 'Pick one:' 'A'
	assert_rc 2 'requires at least one option' tui_select_list_to out 'Pick one:'

	selected=''
	assert_rc 2 'returns 2 on read failure (EOF)' bash -c '
		set -u
		repo_root="$1"
		# shellcheck disable=SC1091
		source "${repo_root}/lib/validation.sh"
		# shellcheck disable=SC1091
		source "${repo_root}/lib/tui.sh"
		selected=""
		tui_select_list_to selected "Pick one:" "A" "B" < /dev/null
	' _ "${repo_root}"

	rm -f "${err_file}"
}

test_init
run_tests
test_finish
