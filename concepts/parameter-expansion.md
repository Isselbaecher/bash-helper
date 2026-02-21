# Parameter Expansion

Parameter expansion is Bash string/value manipulation without spawning external tools.

## Why It Matters

- Safer: fewer quoting mistakes when used correctly.
- Faster: avoids `sed`, `awk`, `cut`, and extra subshells in hot paths.

## Safe Patterns

- Default if unset or empty: `${var:-default}`
- Assign default if unset or empty: `${var:=default}`
- Error if missing: `${var:?message}`
- Alternate value if set: `${var:+alt}`

## TL;DR: Transformation Operators

Assume:

```bash
v="path/to/file.tar.gz"
```

- `${v#pat}`: remove shortest prefix match
- `${v##pat}`: remove longest prefix match
- `${v%pat}`: remove shortest suffix match
- `${v%%pat}`: remove longest suffix match
- `${v/pat/repl}`: replace first match
- `${v//pat/repl}`: replace all matches
- `${v/#pat/repl}`: replace at start only
- `${v/%pat/repl}`: replace at end only

Examples:

```bash
${v#*/}         # to/file.tar.gz
${v##*/}        # file.tar.gz
${v%.*}         # path/to/file.tar
${v%%.*}        # path/to/file
${v/.tar/.zip}  # path/to/file.zip.gz
${v//\//_}      # path_to_file.tar.gz
${v/#path/root} # root/to/file.tar.gz
${v/%gz/xz}     # path/to/file.tar.xz
```

## Safe Usage Rules

- Quote expansions unless you explicitly need word splitting or globbing.
- Prefer `[[ ... ]]` with expansions for tests.
- Validate assumptions before destructive operations.

```bash
[[ -n "${target_dir:-}" ]] || {
	printf 'target_dir is required\n' >&2
	return 2
}
```

## Performance Notes

- Use expansion for small/medium string operations in loops.
- Replace patterns with `${var//old/new}` when practical.
- Avoid external commands for trivial formatting.

```bash
clean="${raw// /_}"
upper="${raw^^}"   # Bash 4+
lower="${raw,,}"   # Bash 4+
```