##################################################
# Dependency
##################################################

if ! declare -F bh_val_out_varname >/dev/null 2>&1; then
	_bh_file_lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
	source "${_bh_file_lib_dir}/validation.sh"
fi

##################################################
# Internal trap-based cleanup registry
##################################################

_bh_file_cleanup_installed=0
_bh_file_cleanup_running=0
_bh_file_cleanup_lockfiles=()
_bh_file_cleanup_tmpdirs=()
_bh_file_prev_exit_trap_cmd=''
_bh_file_prev_int_trap_cmd=''
_bh_file_prev_term_trap_cmd=''
_bh_file_prev_hup_trap_cmd=''
_bh_file_prev_quit_trap_cmd=''

_bh_file_lock_path_to() {
	if (( $# < 2 || $# > 3 )); then
		printf 'usage: _bh_file_lock_path_to <out_varname> <lock_name> [lock_dir]\n' >&2
		return 2
	fi

	local out_varname="${1}"
	local lock_name="${2}"
	local lock_dir="${3-}"

	bh_val_out_varname "${out_varname}" '_bh_file_lock_path_to' || return

	[[ -n "${lock_name}" ]] || {
		printf '_bh_file_lock_path_to: lock_name must not be empty\n' >&2
		return 2
	}

	if [[ -z "${lock_dir}" ]]; then
		if [[ -n "${XDG_RUNTIME_DIR-}" && -d "${XDG_RUNTIME_DIR}" && -w "${XDG_RUNTIME_DIR}" ]]; then
			lock_dir="${XDG_RUNTIME_DIR}"
		else
			lock_dir="${TMPDIR:-/tmp}"
		fi
	fi
	printf -v "${out_varname}" '%s' "${lock_dir%/}/${lock_name}"
}

_bh_file_capture_trap_cmd_to() {
	if (( $# != 2 )); then
		printf 'usage: _bh_file_capture_trap_cmd_to <out_varname> <signal>\n' >&2
		return 2
	fi

	local out_varname="${1}"
	local signal_name="${2}"
	local trap_line trap_cmd

	bh_val_out_varname "${out_varname}" '_bh_file_capture_trap_cmd_to' || return

	trap_line="$(trap -p "${signal_name}")"
	trap_cmd=''

	if [[ -n "${trap_line}" && ${trap_line} == trap\ --\ *\ " ${signal_name}" ]]; then
		trap_cmd="${trap_line#trap -- \'}"
		trap_cmd="${trap_cmd%\' "${signal_name}"}"
	fi

	printf -v "${out_varname}" '%s' "${trap_cmd}"
}


_bh_file_cleanup_dispatcher() {
	local rc=$?
	local signal_name="${1-}"
	local chained_cmd=''
	local path

	(( _bh_file_cleanup_running == 1 )) && return 0
	_bh_file_cleanup_running=1

	case "${signal_name}" in
		INT)
			rc=130
			chained_cmd="${_bh_file_prev_int_trap_cmd}"
			;;
		TERM)
			rc=143
			chained_cmd="${_bh_file_prev_term_trap_cmd}"
			;;
		HUP)
			rc=129
			chained_cmd="${_bh_file_prev_hup_trap_cmd}"
			;;
		QUIT)
			rc=131
			chained_cmd="${_bh_file_prev_quit_trap_cmd}"
			;;
		'')
			chained_cmd="${_bh_file_prev_exit_trap_cmd}"
			;;
		*)
			;;
	esac

	for path in "${_bh_file_cleanup_lockfiles[@]}"; do
		[[ -n "${path}" && "${path}" != '/' ]] && rm -f -- "${path}"
	done

	for path in "${_bh_file_cleanup_tmpdirs[@]}"; do
		[[ -n "${path}" && "${path}" != '/' ]] && rm -rf -- "${path}"
	done

	if [[ -n "${chained_cmd}" ]]; then
		eval "${chained_cmd}"
	fi

	exit "${rc}"
}

_bh_file_cleanup_install_trap() {
	local trap_line

	(( _bh_file_cleanup_installed == 1 )) && return 0

	_bh_file_capture_trap_cmd_to _bh_file_prev_exit_trap_cmd EXIT || return
	_bh_file_capture_trap_cmd_to _bh_file_prev_int_trap_cmd INT || return
	_bh_file_capture_trap_cmd_to _bh_file_prev_term_trap_cmd TERM || return
	_bh_file_capture_trap_cmd_to _bh_file_prev_hup_trap_cmd HUP || return
	_bh_file_capture_trap_cmd_to _bh_file_prev_quit_trap_cmd QUIT || return

	trap '_bh_file_cleanup_dispatcher INT' INT
	trap '_bh_file_cleanup_dispatcher TERM' TERM
	trap '_bh_file_cleanup_dispatcher HUP' HUP
	trap '_bh_file_cleanup_dispatcher QUIT' QUIT
	trap _bh_file_cleanup_dispatcher EXIT
	_bh_file_cleanup_installed=1
}

##################################################
# file_lock_acquire <lock_name> [lock_dir]
#
# Creates a lockfile atomically (noclobber).
# If <lock_dir> is empty or omitted, defaults to:
#   1) XDG_RUNTIME_DIR (if writable), otherwise 2) TMPDIR or /tmp.
# Auto-registers cleanup on EXIT (script/shell end), not function return.
# Returns 0 on success, 1 if lock exists/cannot be created, 2 on usage error.
##################################################
file_lock_acquire() {
	if (( $# < 1 || $# > 2 )); then
		printf 'usage: file_lock_acquire <lock_name> [lock_dir]\n' >&2
		return 2
	fi

	local lock_name="${1}"
	local lock_path

	_bh_file_lock_path_to lock_path "${lock_name}" "${2-}" || return

	if ( set -o noclobber; : > "${lock_path}" ) 2>/dev/null; then
		_bh_file_lock_remove_on_exit "${lock_path}" || {
			rm -f -- "${lock_path}"
			printf 'file_lock_acquire: failed to register lock cleanup: %s\n' "${lock_path}" >&2
			return 1
		}
		return 0
	fi

	if [[ -e "${lock_path}" ]]; then
		printf 'file_lock_acquire: lock already exists: %s\n' "${lock_path}" >&2
		return 1
	fi

	printf 'file_lock_acquire: failed to create lockfile: %s\n' "${lock_path}" >&2
	return 1
}

##################################################
# _bh_file_lock_remove_on_exit <lock_path>
#
# Internal helper: registers lockfile cleanup via EXIT trap.
##################################################
_bh_file_lock_remove_on_exit() {
	if (( $# != 1 )); then
		printf 'usage: _bh_file_lock_remove_on_exit <lock_path>\n' >&2
		return 2
	fi

	local lock_path="${1}"
	[[ -n "${lock_path}" ]] || {
		printf '_bh_file_lock_remove_on_exit: lock_path must not be empty\n' >&2
		return 2
	}

	_bh_file_cleanup_install_trap
	_bh_file_cleanup_lockfiles+=("${lock_path}")
}

##################################################
# file_tmpdir_create_to <out_varname> <dirname> [base_path]
#
# Creates a unique temp directory without mktemp and writes the
# path into <out_varname>.
# Auto-registers cleanup on EXIT (script/shell end), not function return.
##################################################
file_tmpdir_create_to() {
	if (( $# < 2 || $# > 3 )); then
		printf 'usage: file_tmpdir_create_to <out_varname> <dirname> [base_path]\n' >&2
		return 2
	fi

	local out_varname="${1}"
	local dirname="${2}"
	local base_path="${3-${TMPDIR:-/tmp}}"

	bh_val_out_varname "${out_varname}" 'file_tmpdir_create_to' || return

	[[ -n "${dirname}" ]] || {
		printf 'file_tmpdir_create_to: dirname must not be empty\n' >&2
		return 2
	}

	[[ -d "${base_path}" ]] || {
		printf 'file_tmpdir_create_to: base_path does not exist: %s\n' "${base_path}" >&2
		return 1
	}

	local attempt candidate seed
	seed="${EPOCHREALTIME-${SECONDS}}"

	for (( attempt = 0; attempt < 100; attempt++ )); do
		candidate="${base_path%/}/${dirname}.$$.${RANDOM}.${seed}.${attempt}"
		if mkdir -- "${candidate}" 2>/dev/null; then
			_bh_file_tmpdir_remove_on_exit "${candidate}" || {
				rm -rf -- "${candidate}"
				printf 'file_tmpdir_create_to: failed to register tmpdir cleanup: %s\n' "${candidate}" >&2
				return 1
			}
			printf -v "${out_varname}" '%s' "${candidate}"
			return 0
		fi
	done

	printf 'file_tmpdir_create_to: failed to create unique temp dir in: %s\n' "${base_path}" >&2
	return 1
}

##################################################
# _bh_file_tmpdir_remove_on_exit <tmp_dir>
#
# Internal helper: registers temp directory cleanup via EXIT trap.
##################################################
_bh_file_tmpdir_remove_on_exit() {
	if (( $# != 1 )); then
		printf 'usage: _bh_file_tmpdir_remove_on_exit <tmp_dir>\n' >&2
		return 2
	fi

	local tmp_dir="${1}"
	[[ -n "${tmp_dir}" && "${tmp_dir}" != '/' ]] || {
		printf '_bh_file_tmpdir_remove_on_exit: unsafe tmp_dir: %q\n' "${tmp_dir}" >&2
		return 2
	}

	_bh_file_cleanup_install_trap
	_bh_file_cleanup_tmpdirs+=("${tmp_dir}")
}