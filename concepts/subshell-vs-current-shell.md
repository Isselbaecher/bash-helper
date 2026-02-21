# Subshell vs Current Shell

Understanding where code runs prevents subtle bugs.

## Current Shell

Runs in the same process:

- variable changes persist
- `cd` persists
- shell options persist

```bash
count=0
while IFS= read -r _; do
	((count++))
done < "${file}"
printf '%d\n' "${count}"   # value persists
```

## Subshell

Runs in a child process. State changes do not come back.

```bash
count=0
cat "${file}" | while IFS= read -r _; do
	((count++))
done
printf '%d\n' "${count}"   # often still 0
```

## Safe Guidelines

- Prefer redirection loops (`while ...; done < file`) when you need persistent state.
- Use subshells intentionally to isolate side effects.
- Be careful with pipelines when counters/variables must survive.

## Performance Notes

- Subshells and extra pipelines add process overhead.
- In loops, prefer builtins and redirections to reduce forks.
- For heavy data transformation, one external tool may still be cleaner/faster than many shell steps.