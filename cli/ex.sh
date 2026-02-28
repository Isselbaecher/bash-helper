#!/usr/bin/env bash

##################################################
# ex
#
# Extracts one or more archives into a target directory.
#
# Usage:
#   ex [-d target_dir] file [file ...]
#
# Options:
#   -d target_dir  Extraction target (default: current dir)
#   -h, --help     Show help text
#
# Supported formats:
#   .tar .tar.gz .tgz .tar.bz2 .tbz2 .tar.xz .txz
#   .zip .gz .bz2 .xz .7z .rar
#
# Output:
#   - Per-file status lines for multi-file runs
#   - Final summary: total / succeeded / failed
##################################################
ex() {
	local usage='usage: ex [-d target_dir] file [file ...]'
	local help_text
	local target_dir='.'
	local -a files=()
	local -a result_statuses=()
	local -a result_files=()
	local arg
	local file
	local total='0'
	local succeeded='0'
	local failed='0'
	local i

	help_text=$'Extract archives into a target directory.\n\n'
	help_text+="${usage}"$'\n\n'
	help_text+=$'Options:\n'
	help_text+=$'  -d target_dir  Extraction target (default: .)\n'
	help_text+=$'  -h, --help     Show this help text\n\n'
	help_text+=$'Supported formats:\n'
	help_text+=$'  .tar .tar.gz .tgz .tar.bz2 .tbz2 .tar.xz .txz\n'
	help_text+=$'  .zip .gz .bz2 .xz .7z .rar\n\n'
	help_text+=$'Examples:\n'
	help_text+=$'  ex archive.zip\n'
	help_text+=$'  ex -d out archive1.zip archive2.tar.gz\n'

	while (( $# > 0 )); do
		arg="${1}"
		case "${arg}" in
			-h|--help)
				printf '%s' "${help_text}"
				return 0
				;;
			-d)
				if (( $# < 2 )); then
					printf '%s\n' "${usage}" >&2
					printf 'ex: missing value for -d\n' >&2
					return 2
				fi
				target_dir="${2}"
				shift 2
				;;
			--)
				shift
				while (( $# > 0 )); do
					files+=("${1}")
					shift
				done
				break
				;;
			-*)
				printf '%s\n' "${usage}" >&2
				printf 'ex: unknown option: %q\n' "${arg}" >&2
				return 2
				;;
			*)
				files+=("${arg}")
				shift
				;;
		esac
	done

	if (( ${#files[@]} == 0 )); then
		printf '%s\n' "${usage}" >&2
		printf 'ex: at least one file is required\n' >&2
		return 2
	fi

	if [[ -e "${target_dir}" && ! -d "${target_dir}" ]]; then
		printf 'ex: target exists and is not a directory: %q\n' "${target_dir}" >&2
		return 2
	fi

	if [[ ! -d "${target_dir}" ]]; then
		mkdir -p -- "${target_dir}" || {
			printf 'ex: failed to create target directory: %q\n' "${target_dir}" >&2
			return 2
		}
	fi

	for file in "${files[@]}"; do
		total=$(( total + 1 ))

		if [[ ! -f "${file}" ]]; then
			printf 'ex: file not found: %q\n' "${file}" >&2
			failed=$(( failed + 1 ))
			result_statuses+=("FAILED")
			result_files+=("${file}")
			continue
		fi

		printf 'Extracting: %s -> %s\n' "${file}" "${target_dir}" >&2

		case "${file}" in
			*.tar|*.tar.gz|*.tgz|*.tar.bz2|*.tbz2|*.tar.xz|*.txz)
				if tar -xf "${file}" -C "${target_dir}"; then
					succeeded=$(( succeeded + 1 ))
					result_statuses+=("SUCCESS")
				else
					failed=$(( failed + 1 ))
					result_statuses+=("FAILED")
				fi
				result_files+=("${file}")
				;;
			*.zip)
				if unzip -o -q "${file}" -d "${target_dir}"; then
					succeeded=$(( succeeded + 1 ))
					result_statuses+=("SUCCESS")
				else
					failed=$(( failed + 1 ))
					result_statuses+=("FAILED")
				fi
				result_files+=("${file}")
				;;
			*.gz)
				if gzip -dc -- "${file}" > "${target_dir}/$(basename -- "${file%.gz}")"; then
					succeeded=$(( succeeded + 1 ))
					result_statuses+=("SUCCESS")
				else
					failed=$(( failed + 1 ))
					result_statuses+=("FAILED")
				fi
				result_files+=("${file}")
				;;
			*.bz2)
				if bzip2 -dc -- "${file}" > "${target_dir}/$(basename -- "${file%.bz2}")"; then
					succeeded=$(( succeeded + 1 ))
					result_statuses+=("SUCCESS")
				else
					failed=$(( failed + 1 ))
					result_statuses+=("FAILED")
				fi
				result_files+=("${file}")
				;;
			*.xz)
				if xz -dc -- "${file}" > "${target_dir}/$(basename -- "${file%.xz}")"; then
					succeeded=$(( succeeded + 1 ))
					result_statuses+=("SUCCESS")
				else
					failed=$(( failed + 1 ))
					result_statuses+=("FAILED")
				fi
				result_files+=("${file}")
				;;
			*.7z)
				if 7z x -y -o"${target_dir}" -- "${file}" >/dev/null; then
					succeeded=$(( succeeded + 1 ))
					result_statuses+=("SUCCESS")
				else
					failed=$(( failed + 1 ))
					result_statuses+=("FAILED")
				fi
				result_files+=("${file}")
				;;
			*.rar)
				if unrar x -o+ -- "${file}" "${target_dir}" >/dev/null; then
					succeeded=$(( succeeded + 1 ))
					result_statuses+=("SUCCESS")
				else
					failed=$(( failed + 1 ))
					result_statuses+=("FAILED")
				fi
				result_files+=("${file}")
				;;
			*)
				printf 'ex: unsupported archive format: %q\n' "${file}" >&2
				failed=$(( failed + 1 ))
				result_statuses+=("FAILED")
				result_files+=("${file}")
				;;
		esac
	done

	if (( total > 1 )); then
		printf 'ex results:\n' >&2
		for (( i = 0; i < ${#result_files[@]}; i++ )); do
			printf '[%-7s] %s\n' "${result_statuses[i]}" "${result_files[i]}" >&2
		done
	fi

	printf 'ex summary: total=%d succeeded=%d failed=%d\n' "${total}" "${succeeded}" "${failed}" >&2

	if (( failed > 0 )); then
		printf 'ex: %d extraction(s) failed\n' "${failed}" >&2
		return 1
	fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	ex "$@"
fi