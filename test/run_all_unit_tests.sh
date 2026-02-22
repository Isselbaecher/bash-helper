#!/usr/bin/env bash

set -u

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_root}" || exit

failed=0

for test_script in ./test/unit/unit_test_*.sh; do
    if [[ ! -f "${test_script}" ]]; then
        continue
    fi

    printf '\n>>> Running %s\n' "${test_script}"
    if ! bash "${test_script}"; then
        failed=$(( failed + 1 ))
    fi
done

if (( failed > 0 )); then
    printf '\nUnit test suites failed: %d\n' "${failed}" >&2
    exit 1
fi

printf '\nAll unit test suites passed.\n'
