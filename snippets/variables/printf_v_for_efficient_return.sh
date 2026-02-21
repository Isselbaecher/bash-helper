# var_upper_to <varname_out> <input>
# Writes uppercase version of <input> into variable named by <varname_out>.
# Bash: 4.0+ (for ${var^^})
var_upper_to() {
    local __varname_out="$1"
    local __input="$2"

    # Always validate
    [[ $__varname_out =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] || {
        printf 'var_upper_to: invalid variable name: %q\n' "$__varname_out" >&2
        return 2
    }

    # Output directly to the variable using printf -v
    # This is more efficient than using command substitution (echo, |, etc.)
    # Note: ${var^^} is a Bash 4.0+ feature for uppercase conversion
    # For one-off calls, command substitution is usually fine
    # For hot paths (many calls), this avoids extra process overhead
    printf -v "$__varname_out" '%s' "${__input^^}"
}