##################################################
# bh_val_out_varname <varname> [context]
#
# Validates a variable name for safe use with printf -v.
# Returns 0 on success, 2 on invalid name.
##################################################
bh_val_out_varname() {
	if (( $# < 1 || $# > 2 )); then
		printf 'usage: bh_val_out_varname <varname> [context]\n' >&2
		return 2
	fi

	local varname="${1}"
	local context="${2-bh_val_out_varname}"

	[[ ${varname} =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] || {
		printf '%s: invalid variable name: %q\n' "${context}" "${varname}" >&2
		return 2
	}
}

##################################################
# bh_val_int <value> [label]
#
# Validates signed integer input.
# Returns 0 on success, 2 on invalid integer.
##################################################
bh_val_int() {
	if (( $# < 1 || $# > 2 )); then
		printf 'usage: bh_val_int <value> [label]\n' >&2
		return 2
	fi

	local value="${1}"
	local label="${2-value}"

	[[ ${value} =~ ^-?[0-9]+$ ]] || {
		printf '%s: expected integer, got: %q\n' "${label}" "${value}" >&2
		return 2
	}
}

##################################################
# bh_check_cmd <cmd> [cmd...]
#
# Verifies that each command name resolves via command -v.
# Returns 0 when all commands exist, 127 when any is missing.
##################################################
bh_check_cmd() {
	local cmd
	for cmd in "$@"; do
		command -v -- "${cmd}" >/dev/null 2>&1 || return 127
	done
}

##################################################
# bh_confirm [prompt]
#
# Prompts the user for confirmation.
# Accepts y/yes (case-insensitive) as confirmation.
# Returns 0 for yes, 1 for no/empty/other input.
##################################################
bh_confirm() {
	local reply
	local prompt="${1:-Continue?} [y/N] "

	read -r -p "${prompt}" reply
	[[ ${reply} =~ ^[Yy]([eE][sS])?$ ]]
}

##################################################
# bh_is_set <varname>
#
# Returns success when <varname> exists in the current shell
# scope (even if it is set to an empty string).
#
# Returns:
#   0 if variable is set
#   1 if variable is not set
#   2 on invalid arguments or invalid variable name
##################################################
bh_is_set() {
	if (( $# != 1 )); then
		printf 'usage: bh_is_set <varname>\n' >&2
		return 2
	fi

	local varname="${1}"
	bh_val_out_varname "${varname}" 'bh_is_set' || return 2

	[[ -n ${!varname+x} ]]
}

##################################################
# bh_require_var <varname>
#
# Ensures <varname> is set (empty value is allowed).
#
# Returns:
#   0 if variable is set
#   2 if variable is not set, invalid args, or invalid varname
##################################################
bh_require_var() {
	if (( $# != 1 )); then
		printf 'usage: bh_require_var <varname>\n' >&2
		return 2
	fi

	local varname="${1}"
	bh_val_out_varname "${varname}" 'bh_require_var' || return 2

	if ! bh_is_set "${varname}"; then
		printf 'Required variable %s is not set\n' "${varname}" >&2
		return 2
	fi
}

##################################################
# bh_require_nonempty_var <varname>
#
# Ensures <varname> is set and not empty.
#
# Returns:
#   0 if variable is set and non-empty
#   2 if variable is not set/empty, invalid args, or invalid varname
##################################################
bh_require_nonempty_var() {
	if (( $# != 1 )); then
		printf 'usage: bh_require_nonempty_var <varname>\n' >&2
		return 2
	fi

	local varname="${1}"
	bh_val_out_varname "${varname}" 'bh_require_nonempty_var' || return 2

	if [[ -z ${!varname+x} || -z ${!varname} ]]; then
		printf 'Required variable %s is not set or empty\n' "${varname}" >&2
		return 2
	fi
}

_bh_require_path_kind() {
	if (( $# != 3 )); then
		printf 'usage: _bh_require_path_kind <kind> <path> <func_name>\n' >&2
		return 2
	fi

	local kind="${1}"
	local path="${2}"
	local func_name="${3}"

	if [[ -z "${path}" ]]; then
		printf '%s: path must not be empty\n' "${func_name}" >&2
		return 2
	fi

	case "${kind}" in
		file)
			[[ -f "${path}" ]] || {
				printf '%s: required regular file not found: %q\n' "${func_name}" "${path}" >&2
				return 2
			}
			;;
		dir)
			[[ -d "${path}" ]] || {
				printf '%s: required directory not found: %q\n' "${func_name}" "${path}" >&2
				return 2
			}
			;;
		readable)
			[[ -r "${path}" ]] || {
				printf '%s: required readable path not found/access denied: %q\n' "${func_name}" "${path}" >&2
				return 2
			}
			;;
		writable)
			[[ -w "${path}" ]] || {
				printf '%s: required writable path not found/access denied: %q\n' "${func_name}" "${path}" >&2
				return 2
			}
			;;
		executable)
			[[ -x "${path}" ]] || {
				printf '%s: required executable path not found/access denied: %q\n' "${func_name}" "${path}" >&2
				return 2
			}
			;;
		*)
			printf '_bh_require_path_kind: invalid kind: %q\n' "${kind}" >&2
			return 2
			;;
	esac
}

##################################################
# bh_require_file <path>
#
# Ensures <path> exists and is a regular file.
#
# Returns:
#   0 if path is a regular file
#   2 otherwise (or invalid args)
##################################################
bh_require_file() {
	if (( $# != 1 )); then
		printf 'usage: bh_require_file <path>\n' >&2
		return 2
	fi

	_bh_require_path_kind file "${1}" 'bh_require_file'
}

##################################################
# bh_require_dir <path>
#
# Ensures <path> exists and is a directory.
#
# Returns:
#   0 if path is a directory
#   2 otherwise (or invalid args)
##################################################
bh_require_dir() {
	if (( $# != 1 )); then
		printf 'usage: bh_require_dir <path>\n' >&2
		return 2
	fi

	_bh_require_path_kind dir "${1}" 'bh_require_dir'
}

##################################################
# bh_require_readable <path>
#
# Ensures <path> is readable by the current user.
#
# Returns:
#   0 if path is readable
#   2 otherwise (or invalid args)
##################################################
bh_require_readable() {
	if (( $# != 1 )); then
		printf 'usage: bh_require_readable <path>\n' >&2
		return 2
	fi

	_bh_require_path_kind readable "${1}" 'bh_require_readable'
}

##################################################
# bh_require_writable <path>
#
# Ensures <path> is writable by the current user.
#
# Returns:
#   0 if path is writable
#   2 otherwise (or invalid args)
##################################################
bh_require_writable() {
	if (( $# != 1 )); then
		printf 'usage: bh_require_writable <path>\n' >&2
		return 2
	fi

	_bh_require_path_kind writable "${1}" 'bh_require_writable'
}

##################################################
# bh_require_executable <path>
#
# Ensures <path> is executable by the current user.
#
# Returns:
#   0 if path is executable
#   2 otherwise (or invalid args)
##################################################
bh_require_executable() {
	if (( $# != 1 )); then
		printf 'usage: bh_require_executable <path>\n' >&2
		return 2
	fi

	_bh_require_path_kind executable "${1}" 'bh_require_executable'
}

# Requrie parent dir writeable