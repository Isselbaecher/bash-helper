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

## Example

### `var_upper_to`

File: `snippets/variables/printf_v_for_efficient_return.sh`

Converts an input string to uppercase and writes directly to an output variable name using `printf -v`.

Why this pattern is useful:

- avoids command substitution overhead
- avoids subshells/pipelines for simple transformations
- validates variable names before assignment

## Contributing

Suggestions and better ideas are welcome.

If you want to contribute, feel free to open a pull request with:

- cleaner or safer Bash patterns
- better naming or structure ideas
- improvements to existing snippets
- new snippets with short usage examples

## License

See [LICENSE](LICENSE).
