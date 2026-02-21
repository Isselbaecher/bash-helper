##################################################
# Logging configuration
##################################################

# Global threshold for emitted logs.
# Accepted values: DEBUG, INFO, WARN, ERROR
# Default: INFO
: "${BASH_HELPER_LOG_LEVEL:=INFO}"

_bh_log_pid="${BASHPID}"
_bh_log_threshold_level_cached=''
_bh_log_threshold_num_cached=20

##################################################
# Internal helpers
##################################################

# _bh_log_level_to_num_to <out_varname> <level>
# Maps log level to numeric severity for comparisons.
# DEBUG=10, INFO=20, WARN=30, ERROR=40
_bh_log_level_to_num_to() {
	if (( $# != 2 )); then
		printf 'usage: _bh_log_level_to_num_to <out_varname> <level>\n' >&2
		return 2
	fi

	local out_varname="${1}"
	local level="${2^^}"

	case "${level}" in
		DEBUG) printf -v "${out_varname}" '%s' '10' ;;
		INFO)  printf -v "${out_varname}" '%s' '20' ;;
		WARN)  printf -v "${out_varname}" '%s' '30' ;;
		ERROR) printf -v "${out_varname}" '%s' '40' ;;
		*)
			printf '_bh_log_level_to_num_to: invalid level: %q\n' "${level}" >&2
			return 2
			;;
	esac
}

# Refreshes cached numeric threshold when BASH_HELPER_LOG_LEVEL changes.
_bh_log_refresh_threshold_cache() {
	local level_upper
	local threshold_num

	level_upper="${BASH_HELPER_LOG_LEVEL^^}"
	if [[ "${level_upper}" == "${_bh_log_threshold_level_cached}" ]]; then
		return 0
	fi

	_bh_log_level_to_num_to threshold_num "${level_upper}" || {
		printf '_bh_log_refresh_threshold_cache: invalid BASH_HELPER_LOG_LEVEL: %q\n' "${BASH_HELPER_LOG_LEVEL}" >&2
		return 2
	}

	_bh_log_threshold_level_cached="${level_upper}"
	_bh_log_threshold_num_cached=${threshold_num}
}

##################################################
# Public API
##################################################

# log_set_level <level>
# Sets global log threshold: DEBUG|INFO|WARN|ERROR
log_set_level() {
	if (( $# != 1 )); then
		printf 'usage: log_set_level <DEBUG|INFO|WARN|ERROR>\n' >&2
		return 2
	fi

	local requested="${1^^}"
	local threshold_num
	_bh_log_level_to_num_to threshold_num "${requested}" || return

	BASH_HELPER_LOG_LEVEL="${requested}"
	_bh_log_threshold_level_cached="${requested}"
	_bh_log_threshold_num_cached=${threshold_num}
}

# log_msg <level> <message>
# Output format:
#   <timestamp> | <LEVEL> | pid=<pid> | <message>
# Routing:
#   WARN/ERROR -> stderr
#   DEBUG/INFO -> stdout
# Returns:
#   0 on success (or when filtered by level), 2 on usage/invalid level.
log_msg() {
	if (( $# != 2 )); then
		printf 'usage: log_msg <DEBUG|INFO|WARN|ERROR> <message>\n' >&2
		return 2
	fi

	local level="${1^^}"
	local message="${2}"
	local ts msg_level_num

	_bh_log_level_to_num_to msg_level_num "${level}" || {
		printf 'log_msg: invalid level: %q\n' "${level}" >&2
		return 2
	}

	_bh_log_refresh_threshold_cache || return
	(( msg_level_num >= _bh_log_threshold_num_cached )) || return 0
	printf -v ts '%(%Y-%m-%dT%H:%M:%S%z)T' -1

	case "${level}" in
		WARN|ERROR)
			printf '%s | %-5s | pid=%s | %s\n' "${ts}" "${level}" "${_bh_log_pid}" "${message}" >&2
			;;
		*)
			printf '%s | %-5s | pid=%s | %s\n' "${ts}" "${level}" "${_bh_log_pid}" "${message}"
			;;
	esac
}

# log_debug <message>
# Convenience wrapper for log_msg DEBUG.
log_debug() {
	log_msg DEBUG "${*}"
}

# log_info <message>
# Convenience wrapper for log_msg INFO.
log_info() {
	log_msg INFO "${*}"
}

# log_warn <message>
# Convenience wrapper for log_msg WARN.
log_warn() {
	log_msg WARN "${*}"
}

# log_error <message>
# Convenience wrapper for log_msg ERROR.
log_error() {
	log_msg ERROR "${*}"
}

