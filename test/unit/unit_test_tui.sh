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

	# tui_input_to
	local input_value=''
	tui_input_to input_value 'Your name' <<< 'Lukas' 2>"${err_file}" >/dev/null
	err="$(<"${err_file}")"
	assert_match 'Your name:' "${err}" 'tui_input_to prints prompt'
	assert_eq 'Lukas' "${input_value}" 'tui_input_to stores provided value'

	input_value=''
	tui_input_to input_value 'Environment' 'dev' <<< '' 2>"${err_file}" >/dev/null
	err="$(<"${err_file}")"
	assert_match 'Environment \[dev\]:' "${err}" 'tui_input_to prints prompt with default'
	assert_eq 'dev' "${input_value}" 'tui_input_to applies default on empty input'

	assert_rc 2 'tui_input_to rejects invalid output varname' tui_input_to '1bad' 'Prompt'
	assert_rc 2 'tui_input_to usage error on missing args' tui_input_to out
	assert_rc 2 'tui_input_to returns 2 on EOF' bash -c '
		set -u
		repo_root="$1"
		# shellcheck disable=SC1091
		source "${repo_root}/lib/validation.sh"
		# shellcheck disable=SC1091
		source "${repo_root}/lib/tui.sh"
		val=""
		tui_input_to val "Prompt" < /dev/null
	' _ "${repo_root}"

	# tui_secret_to
	local secret=''
	tui_secret_to secret 'Token' <<< 'super-secret' 2>"${err_file}" >/dev/null
	err="$(<"${err_file}")"
	assert_match 'Token:' "${err}" 'tui_secret_to prints prompt'
	assert_eq 'super-secret' "${secret}" 'tui_secret_to stores secret value'

	secret=''
	tui_secret_to secret 'Token' 'fallback-token' <<< '' 2>"${err_file}" >/dev/null
	err="$(<"${err_file}")"
	assert_match 'Token \[hidden, default set\]:' "${err}" 'tui_secret_to prints prompt with default indicator'
	assert_eq 'fallback-token' "${secret}" 'tui_secret_to applies default on empty input'

	assert_rc 2 'tui_secret_to rejects invalid output varname' tui_secret_to '1bad' 'Token'
	assert_rc 2 'tui_secret_to usage error on missing args' tui_secret_to out
	assert_rc 2 'tui_secret_to returns 2 on EOF' bash -c '
		set -u
		repo_root="$1"
		# shellcheck disable=SC1091
		source "${repo_root}/lib/validation.sh"
		# shellcheck disable=SC1091
		source "${repo_root}/lib/tui.sh"
		val=""
		tui_secret_to val "Token" < /dev/null
	' _ "${repo_root}"

	rm -f "${err_file}"
}

test_init
run_tests
test_finish
