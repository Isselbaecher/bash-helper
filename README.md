# Bash Helper

A personal Bash guideline + snippet collection.

This repository is where I keep small, practical Bash patterns I want to reuse and improve over time.

## Repository Structure

```text
.
├── cli/           # Useful bash scriptlets and aliases
├── concepts/      # Bash concepts, ideas, and notes
├── examples/      # Bigger scripts that use these concepts
├── lib/           # Reusable shell helper libraries
├── snippets/      # Focused utility snippets
└── test/          # Tests and validation scripts
```

## Contributing

Suggestions and better ideas are welcome.

If you want to contribute, feel free to open a pull request with:

- cleaner or safer Bash patterns
- better naming or structure ideas
- improvements to existing snippets
- new snippets with short usage examples

## Linting

Run ShellCheck across all shell files:

```bash
bash test/lint-shell.sh
```

Notes:

- Uses style-level checks (`--severity=style`, `--enable=all`).
- On ShellCheck versions that support it, variable bracing style is reported as well.

## CLI Commands

Scripts in `cli/` are designed to be called directly in the terminal.

### newest

List newest regular files recursively.

Usage:

```bash
newest [-n count] [path ...]
```

Options:

- `-n count` Number of files to print (default: `5`)
- `-h`, `--help` Show help text

Examples:

```bash
newest
newest -n 10
newest -n 20 src test
```

### ex

Extract one or more archives to a target directory.

Usage:

```bash
ex [-d target_dir] file [file ...]
```

Options:

- `-d target_dir` Extraction target (default: current directory)
- `-h`, `--help` Show help text

Supported formats:

- `.tar`, `.tar.gz`, `.tgz`, `.tar.bz2`, `.tbz2`, `.tar.xz`, `.txz`
- `.zip`, `.gz`, `.bz2`, `.xz`, `.7z`, `.rar`

Examples:

```bash
ex archive.zip
ex -d out archive1.zip archive2.tar.gz
```

Output behavior:

- Multi-file runs print per-file status lines (`[SUCCESS]` / `[FAILED ]`)
- End-of-run summary prints total, succeeded, and failed counts

### git_undo.sh

Single-purpose git helper for undoing the last non-pushed commit.

Usage:

```bash
git_undo [--soft|--mixed|--hard]
```

Behavior:

- Runs `git_undo`, which resets `HEAD~1` only if the current branch is ahead of its upstream.
- Default mode is `--soft`.

Examples:

```bash
git_undo
git_undo --mixed
git_undo --hard
```

## License

See [LICENSE](LICENSE).
