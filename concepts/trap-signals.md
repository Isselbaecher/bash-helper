# Trap and Signals

`trap` lets you run cleanup or shutdown code on exit/signals.

## Why Use It

- remove temp files reliably
- release locks
- stop child processes
- keep script exits predictable

## Safe Pattern

```bash
tmp_dir="$(mktemp -d)"

cleanup() {
	local rc=$?
	rm -rf -- "$tmp_dir"
	exit "$rc"
}

trap cleanup EXIT INT TERM
```

## Fast Pattern for Loops (Avoid repeated `mktemp`)

If you create many temporary files in a loop, calling `mktemp` each time adds process overhead.
Use one per-script temp directory, then create predictable per-iteration files inside it.

```bash
# One-time unique workspace (single mktemp call)
tmp_root="${TMPDIR:-/tmp}/mytool.$$.${RANDOM}"
mkdir -p -- "$tmp_root" || exit 1

cleanup() {
	local rc=$?
	rm -rf -- "$tmp_root"
	exit "$rc"
}

trap cleanup EXIT INT TERM

for i in "${items[@]}"; do
	tmp_file="$tmp_root/work.$i.tmp"
	: > "$tmp_file" || exit 1
	# ... use "$tmp_file" ...
done
```

Why this is fast and safe:

- one directory setup instead of many `mktemp` calls
- all loop temp files stay scoped under a single cleanup root
- trap still guarantees deletion on normal exit and common signals

## Guidelines

- Keep trap handlers short and idempotent.
- Capture `$?` at handler start when preserving status is required.
- Quote all paths in cleanup.
- Prefer named functions over long inline trap strings.

## Common Pitfalls

- Forgetting `TERM`/`INT` in long-running scripts.
- Doing too much work in trap handlers.
- Overwriting trap accidentally without noticing.

## Performance Notes

- Trap overhead is small for typical scripts.
- Heavy logic inside traps can slow shutdown paths.
- Keep cleanup minimal and deterministic.
- In hot loops, avoid spawning extra processes for temp allocation when one workspace dir is enough.