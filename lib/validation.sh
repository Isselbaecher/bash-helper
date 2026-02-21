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
