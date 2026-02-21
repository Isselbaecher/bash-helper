# Exit Codes

Exit codes are how shell commands report success or failure.

- `0` means success.
- Non-zero means failure (`1-255`).

## Safe Defaults

- Return explicit codes in functions: `return 0` on success, non-zero on failure.
- Check command results immediately with `if ! cmd; then ... fi`.
- Avoid relying on `$?` many lines later. Capture/check right away.

## Recommended Conventions

- `1`: generic failure
- `2`: misuse of shell builtins / invalid arguments
- `126`: found but not executable
- `127`: command not found

Use a small project-specific map for custom failures, for example:

- `10`: configuration error
- `11`: dependency missing
- `12`: runtime precondition not met

## Patterns

```bash
do_work() {
	[[ $# -eq 1 ]] || {
		printf 'usage: do_work <path>\n' >&2
		return 2
	}

	local path="$1"
	[[ -e "${path}" ]] || {
		printf 'missing path: %s\n' "${path}" >&2
		return 10
	}

	cp -- "${path}" /tmp/ || return 1
	return 0
}
```

## Safety Notes

- Print errors to stderr (`>&2`).
- Keep messages actionable (what failed and which input).
- In scripts, propagate failures: `do_work "${x}" || exit $?`.

## Performance Notes

- Exit early on invalid input to avoid wasted work.
- Prefer shell builtins for checks (`[[ ... ]]`, `(( ... ))`) over external processes.