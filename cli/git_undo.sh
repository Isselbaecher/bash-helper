#!/usr/bin/env bash

# git_undo [--soft|--mixed|--hard]
# Undo the last commit, but only when it is not pushed.
# Default mode: --soft
git_undo() {
	local usage='usage: git_undo [--soft|--mixed|--hard]'
	local help_text

	help_text=$'Undo the last commit only when it is not pushed.\n\n'
	help_text+="${usage}"$'\n\n'
	help_text+=$'Modes:\n'
	help_text+=$'  --soft   Move HEAD back one commit, keep changes staged\n'
	help_text+=$'  --mixed  Move HEAD back one commit, keep changes unstaged\n'
	help_text+=$'  --hard   Move HEAD back one commit, discard commit and changes\n\n'
	help_text+=$'Default mode: --soft\n'

	if (( $# == 1 )) && [[ "${1}" == '-h' || "${1}" == '--help' ]]; then
		printf '%s' "${help_text}"
		return 0
	fi

	if (( $# > 1 )); then
		printf '%s\n' "${help_text}" >&2
		printf 'git_undo: too many arguments\n' >&2
		return 2
	fi

	git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
		printf 'git_undo: not inside a git repository\n' >&2
		return 2
	}

	local mode='--soft'
	local upstream
	local ahead_count

	if (( $# == 1 )); then
		case "${1}" in
			--soft|--mixed|--hard)
				mode="${1}"
				;;
			*)
				printf '%s\n' "${help_text}" >&2
				printf 'git_undo: invalid mode: %q\n' "${1}" >&2
				return 2
				;;
		esac
	fi

	upstream="$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null)" || {
		printf 'git_undo: current branch has no upstream\n' >&2
		return 2
	}

	ahead_count="$(git rev-list --count '@{u}..HEAD' 2>/dev/null)" || {
		printf 'git_undo: failed to determine ahead/behind status\n' >&2
		return 2
	}

	if [[ ! ${ahead_count} =~ ^[0-9]+$ ]]; then
		printf 'git_undo: invalid ahead count: %q\n' "${ahead_count}" >&2
		return 2
	fi

	if (( ahead_count < 1 )); then
		printf 'git_undo: no unpushed commit to undo (upstream: %s)\n' "${upstream}" >&2
		return 1
	fi

	git reset "${mode}" HEAD~1
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	git_undo "$@"
fi
