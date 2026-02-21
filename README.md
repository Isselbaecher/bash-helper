# Bash Helper

A personal Bash guideline + snippet collection.

This repository is where I keep small, practical Bash patterns I want to reuse and improve over time.

## Repository Structure

```text
.
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

## License

See [LICENSE](LICENSE).
