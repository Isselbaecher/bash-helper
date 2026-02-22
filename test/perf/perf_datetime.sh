#!/usr/bin/env bash

set -u

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# shellcheck disable=SC1091
source "${repo_root}/lib/validation.sh"
# shellcheck disable=SC1091
source "${repo_root}/lib/datetime.sh"
# shellcheck disable=SC1091
source "${repo_root}/lib/performance.sh"

target_base_case_ms() {
	local label="${1}"
	local iterations="${2}"

	case "${label}:${iterations}" in
		epoch_ms_now:1) printf '%s' 14 ;;
		epoch_ms_now:10) printf '%s' 18 ;;
		epoch_ms_now:100) printf '%s' 47 ;;

		dt_to_epoch:1) printf '%s' 82 ;;
		dt_to_epoch:10) printf '%s' 18 ;;
		dt_to_epoch:100) printf '%s' 46 ;;

		epoch_to_date:1) printf '%s' 16 ;;
		epoch_to_date:10) printf '%s' 26 ;;
		epoch_to_date:100) printf '%s' 65 ;;

		epoch_to_dt:1) printf '%s' 14 ;;
		epoch_to_dt:10) printf '%s' 18 ;;
		epoch_to_dt:100) printf '%s' 65 ;;

		dt_to_short:1) printf '%s' 15 ;;
		dt_to_short:10) printf '%s' 27 ;;
		dt_to_short:100) printf '%s' 132 ;;

		diff_human:1) printf '%s' 3 ;;
		diff_human:10) printf '%s' 8 ;;
		diff_human:100) printf '%s' 78 ;;

		*)
			printf 'target_base_case_ms: no explicit target for %s (n=%s)\n' "${label}" "${iterations}" >&2
			return 2
			;;
	esac
}

run_dt_bench_group() {
	local iterations="${1}"
	local i
	local out epoch short human
	local target_ms

	perf_report_section_header "datetime benchmark: ${iterations} iterations"
	perf_measure_to_report_reset

	target_ms="$(target_base_case_ms epoch_ms_now "${iterations}")"
	perf_measure_to_report 'epoch_ms_now' "${iterations}" "${target_ms}"
	for (( i = 0; i < iterations; i++ )); do
		dt_epoch_ms_now_to out
	done

	target_ms="$(target_base_case_ms dt_to_epoch "${iterations}")"
	perf_measure_to_report 'dt_to_epoch' "${iterations}" "${target_ms}"
	for (( i = 0; i < iterations; i++ )); do
		dt_datetime_to_epoch_to epoch '2026-02-22 12:34:56'
	done

	target_ms="$(target_base_case_ms epoch_to_date "${iterations}")"
	perf_measure_to_report 'epoch_to_date' "${iterations}" "${target_ms}"
	for (( i = 0; i < iterations; i++ )); do
		dt_epoch_to_date_to out 1767225600
	done

	target_ms="$(target_base_case_ms epoch_to_dt "${iterations}")"
	perf_measure_to_report 'epoch_to_dt' "${iterations}" "${target_ms}"
	for (( i = 0; i < iterations; i++ )); do
		dt_epoch_to_datetime_to out 1767225600
	done

	target_ms="$(target_base_case_ms dt_to_short "${iterations}")"
	perf_measure_to_report 'dt_to_short' "${iterations}" "${target_ms}"
	for (( i = 0; i < iterations; i++ )); do
		dt_datetime_to_short_to short '2026-02-22 12:34:56'
	done

	target_ms="$(target_base_case_ms diff_human "${iterations}")"
	perf_measure_to_report 'diff_human' "${iterations}" "${target_ms}"
	for (( i = 0; i < iterations; i++ )); do
		dt_epoch_diff_human_to human 0 93784005
	done

	perf_measure_to_report
	perf_report

	: "${out}" "${epoch}" "${short}" "${human}"
}

run_dt_cache_hit_100() {
	local i minute second
	local dt_input out
	local epoch_value

	perf_report_section_header 'datetime cache-hit benchmark: 100 passes (0/50/100)'
	perf_measure_to_report_reset

	dt_cache_clear
	perf_measure_to_report 'dt2ep_0hit' 100 4700
	for (( i = 0; i < 100; i++ )); do
		minute=$(( i / 60 ))
		second=$(( i % 60 ))
		printf -v dt_input '2026-02-22 12:%02d:%02d' "${minute}" "${second}"
		dt_datetime_to_epoch_to out "${dt_input}"
	done

	dt_cache_clear
	perf_measure_to_report 'dt2ep_50hit' 100 2350
	for (( i = 0; i < 50; i++ )); do
		minute=$(( i / 60 ))
		second=$(( i % 60 ))
		printf -v dt_input '2026-02-22 12:%02d:%02d' "${minute}" "${second}"
		dt_datetime_to_epoch_to out "${dt_input}"
	done
	for (( i = 0; i < 50; i++ )); do
		minute=$(( i / 60 ))
		second=$(( i % 60 ))
		printf -v dt_input '2026-02-22 12:%02d:%02d' "${minute}" "${second}"
		dt_datetime_to_epoch_to out "${dt_input}"
	done

	dt_cache_clear
	dt_datetime_to_epoch_to out '2026-02-22 12:34:56'
	perf_measure_to_report 'dt2ep_100hit' 100 35
	for (( i = 0; i < 100; i++ )); do
		dt_datetime_to_epoch_to out '2026-02-22 12:34:56'
	done

	dt_cache_clear
	perf_measure_to_report 'ep2dt_0hit' 100 100
	for (( i = 0; i < 100; i++ )); do
		epoch_value=$(( 1767225600 + i ))
		dt_epoch_to_datetime_to out "${epoch_value}"
	done

	dt_cache_clear
	perf_measure_to_report 'ep2dt_50hit' 100 76
	for (( i = 0; i < 50; i++ )); do
		epoch_value=$(( 1767225600 + i ))
		dt_epoch_to_datetime_to out "${epoch_value}"
	done
	for (( i = 0; i < 50; i++ )); do
		epoch_value=$(( 1767225600 + i ))
		dt_epoch_to_datetime_to out "${epoch_value}"
	done

	dt_cache_clear
	dt_epoch_to_datetime_to out 1767225600
	perf_measure_to_report 'ep2dt_100hit' 100 50
	for (( i = 0; i < 100; i++ )); do
		dt_epoch_to_datetime_to out 1767225600
	done

	dt_cache_clear
	perf_measure_to_report 'ep2d_0hit' 100 100
	for (( i = 0; i < 100; i++ )); do
		epoch_value=$(( 1767225600 + i ))
		dt_epoch_to_date_to out "${epoch_value}"
	done

	dt_cache_clear
	perf_measure_to_report 'ep2d_50hit' 100 75
	for (( i = 0; i < 50; i++ )); do
		epoch_value=$(( 1767225600 + i ))
		dt_epoch_to_date_to out "${epoch_value}"
	done
	for (( i = 0; i < 50; i++ )); do
		epoch_value=$(( 1767225600 + i ))
		dt_epoch_to_date_to out "${epoch_value}"
	done

	dt_cache_clear
	dt_epoch_to_date_to out 1767225600
	perf_measure_to_report 'ep2d_100hit' 100 54
	for (( i = 0; i < 100; i++ )); do
		dt_epoch_to_date_to out 1767225600
	done

	perf_measure_to_report
	perf_report

	: "${out}"
}

run_dt_bench_group 1
run_dt_bench_group 10
run_dt_bench_group 100
run_dt_cache_hit_100
