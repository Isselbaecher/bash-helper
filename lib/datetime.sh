##################################################
# Dependency
##################################################

if ! declare -F bh_val_out_varname >/dev/null 2>&1; then
	_bh_datetime_lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
	# shellcheck disable=SC1091
	source "${_bh_datetime_lib_dir}/validation.sh"
fi

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

	local epoch_ms epoch_sec epoch_micro

	if [[ -n "${EPOCHREALTIME-}" ]]; then
		epoch_sec="${EPOCHREALTIME%.*}"
		epoch_micro="${EPOCHREALTIME#*.}"
		epoch_micro="${epoch_micro:0:6}"
		while (( ${#epoch_micro} < 6 )); do
			epoch_micro+="0"
		done
		epoch_ms=$(( epoch_sec * 1000 + 10#${epoch_micro} / 1000 ))
	elif epoch_ms="$(date +%s%3N 2>/dev/null)" && [[ ${epoch_ms} =~ ^[0-9]+$ ]]; then
		:
	else
		epoch_ms="$(( $(date +%s) * 1000 ))"
	fi

	printf -v "${out_varname}" '%s' "${epoch_ms}"
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
	local result

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
		result='0ms'
	else
		local IFS=' '
		result="${parts[*]}"
	fi

	printf -v "${out_varname}" '%s' "${sign}${result}"
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

	local epoch
	if epoch="$(date -d "${dt_input}" +%s 2>/dev/null)" && [[ ${epoch} =~ ^-?[0-9]+$ ]]; then
		:
	elif epoch="$(date -j -f '%Y-%m-%d %H:%M:%S' "${dt_input}" +%s 2>/dev/null)" && [[ ${epoch} =~ ^-?[0-9]+$ ]]; then
		:
	elif epoch="$(date -j -f '%Y-%m-%d' "${dt_input}" +%s 2>/dev/null)" && [[ ${epoch} =~ ^-?[0-9]+$ ]]; then
		:
	else
		printf 'dt_datetime_to_epoch_to: cannot parse datetime: %q\n' "${dt_input}" >&2
		return 1
	fi

	printf -v "${out_varname}" '%s' "${epoch}"
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

	local result
	if result="$(date -d "@${epoch_seconds}" +%F 2>/dev/null)"; then
		:
	elif result="$(date -r "${epoch_seconds}" +%F 2>/dev/null)"; then
		:
	else
		printf 'dt_epoch_to_date_to: cannot convert epoch: %q\n' "${epoch_seconds}" >&2
		return 1
	fi

	printf -v "${out_varname}" '%s' "${result}"
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

	local result
	if result="$(date -d "@${epoch_seconds}" '+%Y-%m-%d %H:%M:%S' 2>/dev/null)"; then
		:
	elif result="$(date -r "${epoch_seconds}" '+%Y-%m-%d %H:%M:%S' 2>/dev/null)"; then
		:
	else
		printf 'dt_epoch_to_datetime_to: cannot convert epoch: %q\n' "${epoch_seconds}" >&2
		return 1
	fi

	printf -v "${out_varname}" '%s' "${result}"
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

	local epoch_seconds dt_normalized dt_today short

	dt_datetime_to_epoch_to epoch_seconds "${dt_input}" || return 1
	dt_epoch_to_datetime_to dt_normalized "${epoch_seconds}" || return 1
	dt_today="$(date +%F)"

	if [[ ${dt_normalized} == "${dt_today}"* ]]; then
		short="${dt_normalized#"${dt_today}"}"
		short="${short# }"
		printf -v "${out_varname}" '%s' "${short}"
		return 0
	fi

	printf -v "${out_varname}" '%s' "${dt_normalized}"
}