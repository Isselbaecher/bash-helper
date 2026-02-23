# mapfile

mapfile (alias: readarray) reads lines into a Bash array using a builtin.

## Key Pattern

```bash
mapfile -t lines < input.txt
```

What this does:

- Reads stdin (here redirected from input.txt).
- Stores each input line as one element in array lines.
- With -t, trailing newline characters are removed from each stored element.

After that:

```bash
printf 'count=%d\n' "${#lines[@]}"
printf 'first=%s\n' "${lines[0]}"
```

## Why It Is Often More Efficient

- It is a Bash builtin, so no external process is spawned for reading.
- It performs the line-loading logic internally in compiled Bash code.
- It avoids per-iteration shell loop overhead in common patterns like while read loops.
- It gives you all lines at once, so downstream array operations can be simpler and faster.

In short: fewer shell-level steps, less control-flow overhead, cleaner code.

## What -t Changes Exactly

Without -t, each element usually ends with a trailing newline.
With -t, that trailing newline is stripped.

This is usually what you want for clean comparisons and output formatting.

## Typical Comparison

Loop style:

```bash
lines=()
while IFS= read -r line; do
	lines+=("${line}")
done < input.txt
```

mapfile style:

```bash
mapfile -t lines < input.txt
```

Both are valid. mapfile is usually shorter and often faster for loading full files.

## Command Output via Process Substitution

To load output from a command, use process substitution with an extra input redirect:

```bash
mapfile -t lines < <(some_command)
```

Why two `<` tokens?

- `<(...)` creates a temporary readable stream path (process substitution).
- The first `<` redirects mapfile stdin from that stream path.

Examples:

```bash
# Git-tracked files into an array
mapfile -t tracked_files < <(git ls-files)

# Directory entries from find
mapfile -t shell_files < <(find . -type f -name '*.sh')

# Filtered output pipeline
mapfile -t warnings < <(some_tool | grep -i warning)
```

This keeps assignments in the current shell (unlike command substitution for arrays),
and avoids line-splitting pitfalls from plain `$(...)`.

## Important Trade-Off

mapfile loads all lines into memory.

- Great for small/medium files or when you need random access.
- Not ideal for very large files or stream processing.

For huge input where you process one line at a time and discard it, a while read loop can be more memory-friendly.

## TL;DR

- Use mapfile -t arr < file when you want the whole file as an array.
- It is typically cleaner and more efficient than manual line-append loops.
- Prefer streaming loops for very large input to reduce memory usage.
