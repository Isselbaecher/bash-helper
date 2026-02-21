# Quoting

Quoting is one of the most important Bash safety topics.

## Rule of Thumb

Quote variables by default.

```bash
rm -- "${file}"
cp -- "${src}" "${dst}"
printf '%s\n' "${value}"
```

## Types of Quotes

- Single quotes `'...'`: literal text, no expansion.
- Double quotes `"..."`: allows variable/command expansion, blocks word splitting and glob expansion.
- Unquoted: allows word splitting and glob expansion (often risky).

## Safe Patterns

- Use `"$@"` to pass all args safely.
- Use arrays for command argument building.
- Use `--` before user-controlled paths for many tools.

```bash
cmd=(grep -F -- "${needle}" "${file}")
"${cmd[@]}"
```

## Common Mistakes

- `for f in $(ls)` (breaks on spaces/newlines).
- `echo ${var}` (word splitting/glob surprises).
- Unquoted paths in `rm`, `mv`, `cp`.

Preferred:

```bash
while IFS= read -r line; do
	printf '%s\n' "${line}"
done < "${input_file}"
```

## Performance Notes

- Good quoting prevents expensive retries/debugging.
- Arrays + proper quoting reduce string re-parsing and brittle shell logic.
- `printf` is usually safer and more predictable than `echo`.