#!/usr/bin/env bash

set -u

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_root}" || exit

failed=0

for perf_script in ./test/perf/perf_*.sh; do
    if [[ ! -f "${perf_script}" ]]; then
        continue
    fi

    printf '\n>>> Running %s\n' "${perf_script}"
    if ! bash "${perf_script}"; then
        failed=$(( failed + 1 ))
    fi
done

if (( failed > 0 )); then
    printf '\nPerformance test scripts failed: %d\n' "${failed}" >&2
    exit 1
fi

printf '\nAll performance test scripts completed successfully.\n'
