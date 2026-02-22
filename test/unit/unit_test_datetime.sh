#!/usr/bin/env bash

set -u

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# shellcheck disable=SC1091
source "${repo_root}/test/assert.sh"

# shellcheck disable=SC1091
source "${repo_root}/lib/validation.sh"
# shellcheck disable=SC1091
source "${repo_root}/lib/datetime.sh"

run_tests() {
	local out epoch_val dt_val date_val short_val human_val
	local dt_input
	local today

	dt_input='2026-02-22 12:34:56'

	# Basic current time function
	dt_epoch_ms_now_to out
	assert_match '^[0-9]+$' "${out}" 'dt_epoch_ms_now_to returns numeric'

	# Round-trip datetime <-> epoch
	dt_datetime_to_epoch_to epoch_val "${dt_input}"
	dt_epoch_to_datetime_to dt_val "${epoch_val}"
	assert_eq "${dt_input}" "${dt_val}" 'roundtrip datetime->epoch->datetime'

	# Date should match datetime prefix
	dt_epoch_to_date_to date_val "${epoch_val}"
	assert_eq "${date_val}" "${dt_val%% *}" 'epoch_to_date matches datetime prefix'

	# Human diff formatting
	dt_epoch_diff_human_to human_val 0 93784005
	assert_eq '1d 2h 3m 4s 5ms' "${human_val}" 'human diff known value'

	# Datetime short: strips current day prefix
	printf -v today '%(%Y-%m-%d)T' -1
	dt_datetime_to_short_to short_val "${today} 12:34:56"
	assert_eq '12:34:56' "${short_val}" 'datetime short strips today prefix'

	# Cache clear should keep behavior correct
	dt_cache_clear
	dt_datetime_to_epoch_to epoch_val "${dt_input}"
	dt_epoch_to_datetime_to dt_val "${epoch_val}"
	assert_eq "${dt_input}" "${dt_val}" 'cache clear keeps conversion behavior'

	# Error paths
	assert_rc 2 'invalid out varname for dt_epoch_ms_now_to' dt_epoch_ms_now_to '1bad'
	assert_rc 2 'invalid epoch integer for dt_epoch_to_date_to' dt_epoch_to_date_to out 'nope'
	assert_rc 1 'unparseable datetime returns 1' dt_datetime_to_epoch_to out 'not-a-datetime'
}

test_init
run_tests
test_finish

