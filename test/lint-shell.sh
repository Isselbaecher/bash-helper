#!/usr/bin/env bash

# Run from anywhere.
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_root}" || (
    printf 'Failed to change to repo root: %s\n' "${repo_root}" >&2
    exit 1
)

if ! command -v shellcheck >/dev/null 2>&1; then
    printf 'shellcheck is required (https://www.shellcheck.net/)\n' >&2
    exit 127
fi

# Globbing instead of find
shopt -s globstar nullglob
shell_files=(./**/*.sh)
shopt -u globstar nullglob

if (( ${#shell_files[@]} == 0 )); then
    printf 'No shell files found.\n'
    exit 0
fi

# ShellCheck reads project settings from .shellcheckrc in repo root.
shellcheck "${shell_files[@]}"
