# Variable Indirection

Variable indirection means using one variable name to read/write another variable.

## Main Approaches

- `printf -v` to assign to a variable by name (safe and fast).
- `declare -n` nameref (Bash 4.3+) for reference-style access.
- `${!name}` for indirect read.

## Safe Validation

Always validate target variable names before indirection:

```bash
[[ $out_var =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] || {
	printf 'invalid variable name: %q\n' "$out_var" >&2
	return 2
}
```

## Preferred Write Pattern

```bash
to_upper_to() {
	local out_var="$1"
	local input="$2"

	[[ $out_var =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] || return 2
	printf -v "$out_var" '%s' "${input^^}"
}
```

## Nameref Example (Bash 4.3+)

```bash
append_suffix() {
	local target_name="$1"
	local suffix="$2"
	local -n target_ref="$target_name"
	target_ref+="$suffix"
}
```

## Safety Notes

- Never use unvalidated names from untrusted input.
- Avoid `eval` for assignment when `printf -v` or nameref works.
- Keep indirect writes localized in small helper functions.

## Performance Notes

- `printf -v` avoids command substitution overhead.
- Indirection is usually cheap; external command usage dominates cost.
- Use simple direct variables where indirection is unnecessary.