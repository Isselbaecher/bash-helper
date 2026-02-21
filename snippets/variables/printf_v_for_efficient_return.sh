# snippet: fn <out_varname> [args...]
var_to_X_to() {
    if (( $# != 2 )); then
        printf 'usage: var_to_X_to <out_varname> <input>\n' >&2
        return 2
    fi

    local out_varname="$1"
    local input="$2"

    # Always validate
    [[ $out_varname =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] || {
        printf 'var_to_X_to: invalid variable name: %q\n' "$out_varname" >&2
        return 2
    }

    # Compute result into local var
    local result
    result="..."

    # Assign without command substitution
    printf -v "$out_varname" '%s' "$result"
}

##################################################
### Example: uppercase conversion
##################################################  
# var_to_upper_to <out_varname> <input>
# Writes uppercase version of <input> into variable named by <out_varname>.
# Bash: 4.0+ (for ${var^^})
var_to_upper_to() {
    if (( $# != 2 )); then
        printf 'usage: var_to_upper_to <out_varname> <input>\n' >&2
        return 2
    fi

    local out_varname="$1"
    local input="$2"

    # Always validate
    [[ $out_varname =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] || {
        printf 'var_to_upper_to: invalid variable name: %q\n' "$out_varname" >&2
        return 2
    }

    # Output directly to the variable using printf -v
    # This is more efficient than using command substitution (echo, |, etc.)
    # Note: ${var^^} is a Bash 4.0+ feature for uppercase conversion
    # For one-off calls, command substitution is usually fine
    # For hot paths (many calls), this avoids extra process overhead
    printf -v "$out_varname" '%s' "${input^^}"
}