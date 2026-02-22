##################################################
# Dependency
##################################################

if ! declare -F bh_val_out_varname >/dev/null 2>&1; then
	_bh_datetime_lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
	source "${_bh_datetime_lib_dir}/validation.sh"
fi

##################################################
# Internal helpers
##################################################

# Caches to avoid repeated expensive datetime parsing/formatting.
declare -gA _bh_dt_cache_dt_to_epoch=()
declare -gA _bh_dt_cache_epoch_to_date=()
declare -gA _bh_dt_cache_epoch_to_dt=()
declare -g _bh_dt_today_cached=''

##################################################
# dt_cache_clear
#
# Clears datetime conversion caches.
# Useful for long-lived shells or tests.
##################################################
dt_cache_clear() {
	_bh_dt_cache_dt_to_epoch=()
	_bh_dt_cache_epoch_to_dt=()
	_bh_dt_cache_epoch_to_date=()
	_bh_dt_today_cached=''
}

_bh_dt_cache_epoch_formats() {
	if (( $# != 1 )); then
		printf 'usage: _bh_dt_cache_epoch_formats <epoch_seconds>\n' >&2
		return 2
	fi

	local epoch_seconds="${1}"
	bh_val_int "${epoch_seconds}" 'epoch_seconds' || return

	if [[ ! -v _bh_dt_cache_epoch_to_date["${epoch_seconds}"] ]]; then
		printf -v _bh_dt_cache_epoch_to_date["${epoch_seconds}"] '%(%Y-%m-%d)T' "${epoch_seconds}"
	fi

	if [[ ! -v _bh_dt_cache_epoch_to_dt["${epoch_seconds}"] ]]; then
		printf -v _bh_dt_cache_epoch_to_dt["${epoch_seconds}"] '%(%Y-%m-%d %H:%M:%S)T' "${epoch_seconds}"
	fi
}

_bh_dt_today_date_to() {
	if (( $# != 1 )); then
		printf 'usage: _bh_dt_today_date_to <out_varname>\n' >&2
		return 2
	fi

	local out_varname="${1}"
	bh_val_out_varname "${out_varname}" '_bh_dt_today_date_to' || return

	# Cache "today" once per shell session for high-frequency callers.
	if [[ -z "${_bh_dt_today_cached}" ]]; then
		printf -v _bh_dt_today_cached '%(%Y-%m-%d)T' -1
	fi

	printf -v "${out_varname}" '%s' "${_bh_dt_today_cached}"
}

_bh_dt_normalize_datetime_to() {
	if (( $# != 2 )); then
		printf 'usage: _bh_dt_normalize_datetime_to <out_varname> <dt_input>\n' >&2
		return 2
	fi

	local out_varname="${1}"
	local dt_input="${2}"
	local dt_epoch dt_normalized_local

	bh_val_out_varname "${out_varname}" '_bh_dt_normalize_datetime_to' || return

	# Fast path: already normalized format.
	if [[ ${dt_input} =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}[[:space:]][0-9]{2}:[0-9]{2}:[0-9]{2}$ ]]; then
		printf -v "${out_varname}" '%s' "${dt_input}"
		return 0
	fi

	dt_datetime_to_epoch_to dt_epoch "${dt_input}" || return 1
	dt_epoch_to_datetime_to dt_normalized_local "${dt_epoch}" || return 1
	printf -v "${out_varname}" '%s' "${dt_normalized_local}"
	return 0
}

##################################################
# dt_epoch_ms_now_to <out_varname>
#
# Writes current epoch milliseconds to <out_varname>.
# Fast path uses Bash 5+ EPOCHREALTIME (no external process).
# Fallback uses date.
##################################################
dt_epoch_ms_now_to() {
	if (( $# != 1 )); then
		printf 'usage: dt_epoch_ms_now_to <out_varname>\n' >&2
		return 2
	fi

	local out_varname="${1}"
	bh_val_out_varname "${out_varname}" 'dt_epoch_ms_now_to' || return

	local dt_now_epoch_ms dt_now_epoch_sec dt_now_epoch_micro

	if [[ -n "${EPOCHREALTIME-}" ]]; then
		dt_now_epoch_sec="${EPOCHREALTIME%.*}"
		dt_now_epoch_micro="${EPOCHREALTIME#*.}"
		dt_now_epoch_micro="${dt_now_epoch_micro:0:6}"
		while (( ${#dt_now_epoch_micro} < 6 )); do
			dt_now_epoch_micro+="0"
		done
		dt_now_epoch_ms=$(( dt_now_epoch_sec * 1000 + 10#${dt_now_epoch_micro} / 1000 ))
	elif dt_now_epoch_ms="$(date +%s%3N 2>/dev/null)" && [[ ${dt_now_epoch_ms} =~ ^[0-9]+$ ]]; then
		:
	else
		dt_now_epoch_ms="$(( $(date +%s) * 1000 ))"
	fi

	printf -v "${out_varname}" '%s' "${dt_now_epoch_ms}"
}

##################################################
# dt_epoch_diff_human_to <out_varname> <start_epoch_ms> <end_epoch_ms>
#
# Writes human-readable diff using units: d h m s ms.
# Missing zero units are omitted. If all are zero, result is 0ms.
# Example: 1d 2h 3m 4s 5ms
##################################################
dt_epoch_diff_human_to() {
	if (( $# != 3 )); then
		printf 'usage: dt_epoch_diff_human_to <out_varname> <start_epoch_ms> <end_epoch_ms>\n' >&2
		return 2
	fi

	local out_varname="${1}"
	local start_epoch_ms="${2}"
	local end_epoch_ms="${3}"
	bh_val_out_varname "${out_varname}" 'dt_epoch_diff_human_to' || return
	bh_val_int "${start_epoch_ms}" 'start_epoch_ms' || return
	bh_val_int "${end_epoch_ms}" 'end_epoch_ms' || return

	local delta_ms sign
	local days hours minutes seconds millis
	local -a parts=()
	local dt_human_diff

	delta_ms=$(( end_epoch_ms - start_epoch_ms ))
	sign=''
	if (( delta_ms < 0 )); then
		sign='-'
		delta_ms=$(( -delta_ms ))
	fi

	days=$(( delta_ms / 86400000 ))
	delta_ms=$(( delta_ms % 86400000 ))

	hours=$(( delta_ms / 3600000 ))
	delta_ms=$(( delta_ms % 3600000 ))

	minutes=$(( delta_ms / 60000 ))
	delta_ms=$(( delta_ms % 60000 ))

	seconds=$(( delta_ms / 1000 ))
	millis=$(( delta_ms % 1000 ))

	(( days > 0 )) && parts+=("${days}d")
	(( hours > 0 )) && parts+=("${hours}h")
	(( minutes > 0 )) && parts+=("${minutes}m")
	(( seconds > 0 )) && parts+=("${seconds}s")
	(( millis > 0 )) && parts+=("${millis}ms")

	if (( ${#parts[@]} == 0 )); then
		dt_human_diff='0ms'
	else
		local IFS=' '
		dt_human_diff="${parts[*]}"
	fi

	printf -v "${out_varname}" '%s' "${sign}${dt_human_diff}"
}

##################################################
# dt_datetime_to_epoch_to <out_varname> <dt_input>
#
# Parses <dt_input> and writes epoch seconds.
# Input is forwarded to date parser (GNU/BSD fallback).
##################################################
dt_datetime_to_epoch_to() {
	if (( $# != 2 )); then
		printf 'usage: dt_datetime_to_epoch_to <out_varname> <dt_input>\n' >&2
		return 2
	fi

	local out_varname="${1}"
	local dt_input="${2}"
	bh_val_out_varname "${out_varname}" 'dt_datetime_to_epoch_to' || return

	local dt_parsed_epoch

	if [[ -v _bh_dt_cache_dt_to_epoch["${dt_input}"] ]]; then
		printf -v "${out_varname}" '%s' "${_bh_dt_cache_dt_to_epoch["${dt_input}"]}"
		return 0
	fi

	if dt_parsed_epoch="$(date -d "${dt_input}" +%s 2>/dev/null)" && [[ ${dt_parsed_epoch} =~ ^-?[0-9]+$ ]]; then
		:
	elif dt_parsed_epoch="$(date -j -f '%Y-%m-%d %H:%M:%S' "${dt_input}" +%s 2>/dev/null)" && [[ ${dt_parsed_epoch} =~ ^-?[0-9]+$ ]]; then
		:
	elif dt_parsed_epoch="$(date -j -f '%Y-%m-%d' "${dt_input}" +%s 2>/dev/null)" && [[ ${dt_parsed_epoch} =~ ^-?[0-9]+$ ]]; then
		:
	else
		printf 'dt_datetime_to_epoch_to: cannot parse datetime: %q\n' "${dt_input}" >&2
		return 1
	fi

	_bh_dt_cache_dt_to_epoch["${dt_input}"]="${dt_parsed_epoch}"
	_bh_dt_cache_epoch_formats "${dt_parsed_epoch}" || return

	printf -v "${out_varname}" '%s' "${dt_parsed_epoch}"
}

##################################################
# dt_epoch_to_date_to <out_varname> <epoch_seconds>
#
# Writes date as YYYY-MM-DD.
##################################################
dt_epoch_to_date_to() {
	if (( $# != 2 )); then
		printf 'usage: dt_epoch_to_date_to <out_varname> <epoch_seconds>\n' >&2
		return 2
	fi

	local out_varname="${1}"
	local epoch_seconds="${2}"
	bh_val_out_varname "${out_varname}" 'dt_epoch_to_date_to' || return
	bh_val_int "${epoch_seconds}" 'epoch_seconds' || return

	_bh_dt_cache_epoch_formats "${epoch_seconds}" || return

	printf -v "${out_varname}" '%s' "${_bh_dt_cache_epoch_to_date["${epoch_seconds}"]}"
}

##################################################
# dt_epoch_to_datetime_to <out_varname> <epoch_seconds>
#
# Writes datetime as YYYY-MM-DD HH:MM:SS.
##################################################
dt_epoch_to_datetime_to() {
	if (( $# != 2 )); then
		printf 'usage: dt_epoch_to_datetime_to <out_varname> <epoch_seconds>\n' >&2
		return 2
	fi

	local out_varname="${1}"
	local epoch_seconds="${2}"
	bh_val_out_varname "${out_varname}" 'dt_epoch_to_datetime_to' || return
	bh_val_int "${epoch_seconds}" 'epoch_seconds' || return

	_bh_dt_cache_epoch_formats "${epoch_seconds}" || return

	printf -v "${out_varname}" '%s' "${_bh_dt_cache_epoch_to_dt["${epoch_seconds}"]}"
}

##################################################
# dt_datetime_to_short_to <out_varname> <dt_input>
#
# Normalizes datetime, then removes YYYY-MM-DD prefix
# if that date equals today.
##################################################
dt_datetime_to_short_to() {
	if (( $# != 2 )); then
		printf 'usage: dt_datetime_to_short_to <out_varname> <dt_input>\n' >&2
		return 2
	fi

	local out_varname="${1}"
	local dt_input="${2}"
	bh_val_out_varname "${out_varname}" 'dt_datetime_to_short_to' || return

	local dt_normalized dt_today dt_short

	_bh_dt_normalize_datetime_to dt_normalized "${dt_input}" || return 1
	_bh_dt_today_date_to dt_today || return

	if [[ ${dt_normalized} == "${dt_today}"* ]]; then
		dt_short="${dt_normalized#"${dt_today}"}"
		dt_short="${dt_short# }"
		printf -v "${out_varname}" '%s' "${dt_short}"
		return 0
	fi

	printf -v "${out_varname}" '%s' "${dt_normalized}"
}