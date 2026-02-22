##################################################
# Dependency
##################################################

if ! declare -F bh_val_out_varname >/dev/null 2>&1; then
    _bh_string_lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    # shellcheck disable=SC1091
    source "${_bh_string_lib_dir}/validation.sh"
fi

##################################################
# str_escape_html_to <out_varname> <input>
#
# Escapes a string for HTML output and writes the result
# to the variable named by <out_varname>.
#
# Escaped characters:
#   & < > " '
#
# Additional named entities supported:
#   Ä ä Ö ö Ü ü ß © € ¢ £ ¥ ® ™
#
# Returns:
#   0 on success
#   2 on invalid arguments or invalid output variable name
##################################################
str_escape_html_to() {
    # API: str_escape_html_to <out_varname> <input>
    if (( $# != 2 )); then
        printf 'usage: str_escape_html_to <out_varname> <input>\n' >&2
        return 2
    fi

    local out_varname="$1"
    local input="$2"

    # Validate variable name before using it with printf -v.
    bh_val_out_varname "${out_varname}" 'str_escape_html_to' || return

    # Work on a local copy to keep input immutable.
    local result="${input}"

    # Fast path: if no escapable characters exist, avoid all replacement passes.
    if [[ ${result} != *'&'* && ${result} != *'<'* && ${result} != *'>'* && ${result} != *'"'* && ${result} != *"'"* && \
          ${result} != *'Ä'* && ${result} != *'ä'* && ${result} != *'Ö'* && ${result} != *'ö'* && ${result} != *'Ü'* && \
          ${result} != *'ü'* && ${result} != *'ß'* && ${result} != *'©'* && ${result} != *'€'* && ${result} != *'¢'* && \
          ${result} != *'£'* && ${result} != *'¥'* && ${result} != *'®'* && ${result} != *'™'* ]]; then
        printf -v "${out_varname}" '%s' "${result}"
        return 0
    fi

    # Escape core HTML characters first.
    # '&' must be first to avoid double-encoding entities introduced later.
    result="${result//&/&amp;}"
    result="${result//</\&lt;}"
    result="${result//>/\&gt;}"
    result="${result//\"/\&quot;}"
    result="${result//\'/\&apos;}"

    # Named entities for German special characters.
    result="${result//Ä/\&Auml;}"
    result="${result//ä/\&auml;}"
    result="${result//Ö/\&Ouml;}"
    result="${result//ö/\&ouml;}"
    result="${result//Ü/\&Uuml;}"
    result="${result//ü/\&uuml;}"
    result="${result//ß/\&szlig;}"

    # Additional named entities used in this project.
    result="${result//©/\&copy;}"
    result="${result//€/\&euro;}"
    result="${result//¢/\&cent;}"
    result="${result//£/\&pound;}"
    result="${result//¥/\&yen;}"
    result="${result//®/\&reg;}"
    result="${result//™/\&trade;}"

    # Return via output variable (no command substitution).
    printf -v "${out_varname}" '%s' "${result}"
}