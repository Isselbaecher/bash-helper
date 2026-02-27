##################################################
# Dependency
##################################################

if ! declare -F bh_val_out_varname >/dev/null 2>&1; then
	_bh_tui_lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
	# shellcheck disable=SC1091
	source "${_bh_tui_lib_dir}/validation.sh"
fi

##################################################
# tui_select_list_to <out_varname> <prompt> <option...>
#
# Shows a numbered menu (1..n), repeatedly prompts until
# a valid selection is entered, and writes the selected
# option text to <out_varname>.
#
# I/O:
#   - Menu and prompt are written to stderr.
#   - Input is read from stdin.
#
# Returns:
#   0 on successful selection
#   2 on usage errors, invalid output variable name,
#     or input read failure (e.g., EOF)
##################################################
tui_select_list_to() {
	if (( $# < 3 )); then
		printf 'usage: tui_select_list_to <out_varname> <prompt> <option...>\n' >&2
		return 2
	fi

	local out_varname="${1}"
	local prompt="${2}"
	shift 2

	bh_val_out_varname "${out_varname}" 'tui_select_list_to' || return

	local -a options=("$@")
	local option_count="${#options[@]}"
	local num_width="${#option_count}"
	local choice
	local idx

	printf '\n+-- %s\n' "${prompt}" >&2
	for idx in "${!options[@]}"; do
		printf '|  %*d) %s\n' "${num_width}" "$(( idx + 1 ))" "${options[idx]}" >&2
	done
	printf '+--\n' >&2

	while :; do
		printf '  > Enter choice [1-%d]: ' "${option_count}" >&2
		if ! read -r choice; then
			printf 'tui_select_list_to: failed to read user input\n' >&2
			return 2
		fi

		if [[ ${choice} =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= option_count )); then
			printf -v "${out_varname}" '%s' "${options[choice-1]}"
			printf '  OK: Selected: %s\n' "${options[choice-1]}" >&2
			return 0
		fi

		printf '  ERROR: Invalid selection: %q (expected 1-%d)\n' "${choice}" "${option_count}" >&2
	done
}

##################################################
# tui_input_to <out_varname> <prompt> [default_value]
#
# Prompts once for input and writes the entered value to
# <out_varname>. If [default_value] is provided and the
# user submits an empty input, default_value is used.
#
# I/O:
#   - Prompt is written to stderr.
#   - Input is read from stdin.
#
# Returns:
#   0 on success
#   2 on usage errors, invalid output variable name,
#     or input read failure (e.g., EOF)
##################################################
tui_input_to() {
	if (( $# < 2 || $# > 3 )); then
		printf 'usage: tui_input_to <out_varname> <prompt> [default_value]\n' >&2
		return 2
	fi

	local out_varname="${1}"
	local prompt="${2}"
	local default_value="${3-}"
	local input

	bh_val_out_varname "${out_varname}" 'tui_input_to' || return

	if (( $# == 3 )); then
		printf '%s [%s]: ' "${prompt}" "${default_value}" >&2
	else
		printf '%s: ' "${prompt}" >&2
	fi

	if ! read -r input; then
		printf 'tui_input_to: failed to read user input\n' >&2
		return 2
	fi

	if [[ -z "${input}" && $# == 3 ]]; then
		input="${default_value}"
	fi

	printf -v "${out_varname}" '%s' "${input}"
}

##################################################
# tui_secret_to <out_varname> <prompt> [default_value]
#
# Prompts once for hidden input and writes the entered
# secret value to <out_varname>. If [default_value] is
# provided and input is empty, default_value is used.
#
# I/O:
#   - Prompt is written to stderr.
#   - Input is read from stdin without terminal echo.
#
# Returns:
#   0 on success
#   2 on usage errors, invalid output variable name,
#     or input read failure (e.g., EOF)
##################################################
tui_secret_to() {
	if (( $# < 2 || $# > 3 )); then
		printf 'usage: tui_secret_to <out_varname> <prompt> [default_value]\n' >&2
		return 2
	fi

	local out_varname="${1}"
	local prompt="${2}"
	local default_value="${3-}"
	local input

	bh_val_out_varname "${out_varname}" 'tui_secret_to' || return

	if (( $# == 3 )); then
		printf '%s [hidden, default set]: ' "${prompt}" >&2
	else
		printf '%s: ' "${prompt}" >&2
	fi

	if ! read -r -s input; then
		printf '\ntui_secret_to: failed to read user input\n' >&2
		return 2
	fi
	printf '\n' >&2

	if [[ -z "${input}" && $# == 3 ]]; then
		input="${default_value}"
	fi

	printf -v "${out_varname}" '%s' "${input}"
}
