#!/usr/bin/env bash

##################################################
# newest
#
# Lists the newest regular files recursively across one
# or more paths.
#
# Usage:
#   newest [-n count] [path ...]
#
# Options:
#   -n count   Number of files to print (default: 5)
#   -h, --help Show help text
#
# Arguments:
#   path       One or more files/directories to scan.
#              Defaults to current directory.
#
# Examples:
#   newest
#   newest -n 10
#   newest -n 20 src test
##################################################
newest() {
	local usage='usage: newest [-n count] [path ...]'
	local help_text
	local n='5'
	local -a paths=()
	local arg
	local path
	local tmp_unsorted
	local tmp_sorted
	local line
	local emitted='0'

	help_text=$'Lists newest regular files recursively.\n\n'
	help_text+="${usage}"$'\n\n'
	help_text+=$'Options:\n'
	help_text+=$'  -n count   Number of files to print (default: 5)\n'
	help_text+=$'  -h, --help Show this help text\n\n'
	help_text+=$'Arguments:\n'
	help_text+=$'  path       One or more files/directories to scan (default: .)\n\n'
	help_text+=$'Examples:\n'
	help_text+=$'  newest\n'
	help_text+=$'  newest -n 10\n'
	help_text+=$'  newest -n 20 src test\n'

	while (( $# > 0 )); do
		arg="${1}"
		case "${arg}" in
			-h|--help)
				printf '%s' "${help_text}"
				return 0
				;;
			-n)
				if (( $# < 2 )); then
					printf '%s\n' "${usage}" >&2
					printf 'newest: missing value for -n\n' >&2
					return 2
				fi
				n="${2}"
				shift 2
				;;
			--)
				shift
				while (( $# > 0 )); do
					paths+=("${1}")
					shift
				done
				break
				;;
			-*)
				printf '%s\n' "${usage}" >&2
				printf 'newest: unknown option: %q\n' "${arg}" >&2
				return 2
				;;
			*)
				paths+=("${arg}")
				shift
				;;
		esac
	done

	if (( ${#paths[@]} == 0 )); then
		paths+=(.)
	fi

	[[ ${n} =~ ^[0-9]+$ ]] || {
		printf 'newest: n must be a non-negative integer: %q\n' "${n}" >&2
		return 2
	}

	(( n > 0 )) || {
		printf 'newest: n must be greater than zero\n' >&2
		return 2
	}

	for path in "${paths[@]}"; do
		[[ -e "${path}" ]] || {
			printf 'newest: path not found: %q\n' "${path}" >&2
			return 2
		}
	done

	tmp_unsorted="$(mktemp)" || {
		printf 'newest: failed to create temporary file\n' >&2
		return 2
	}

	tmp_sorted="$(mktemp)" || {
		rm -f "${tmp_unsorted}"
		printf 'newest: failed to create temporary file\n' >&2
		return 2
	}

	if ! find "${paths[@]}" -type f -printf '%T@ %p\n' 2>/dev/null > "${tmp_unsorted}"; then
		rm -f "${tmp_unsorted}" "${tmp_sorted}"
		printf 'newest: failed to scan paths\n' >&2
		return 2
	fi

	if ! sort -nr "${tmp_unsorted}" > "${tmp_sorted}"; then
		rm -f "${tmp_unsorted}" "${tmp_sorted}"
		printf 'newest: failed to sort file list\n' >&2
		return 2
	fi

	while IFS= read -r line; do
		printf '%s\n' "${line#* }"
		emitted=$(( emitted + 1 ))
		(( emitted >= n )) && break
	done < "${tmp_sorted}"

	rm -f "${tmp_unsorted}" "${tmp_sorted}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	newest "$@"
fi