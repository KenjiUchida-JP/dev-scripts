#!/usr/bin/env bash
# Python version detection helpers

# Convert version string to pyXXX format (e.g., 3.14.2 → py314)
get_py_version() {
    local version="$1"
    local major minor
    major=$(echo "$version" | cut -d. -f1)
    minor=$(echo "$version" | cut -d. -f2)
    echo "py${major}${minor}"
}

# Get X.XX format from version string (e.g., 3.14.2 → 3.14)
get_major_minor() {
    local version="$1"
    echo "$version" | cut -d. -f1,2
}

# Version format validation (alias for validator library function)
validate_version() {
    validate_python_version "$1"
}

# Get latest Python version available via uv
get_latest_python_version() {
    local version
    version=$(uv python list --only-downloads 2>/dev/null | grep -E "^cpython-[0-9]+\.[0-9]+\.[0-9]+-" | grep -v "freethreaded" | head -1 | sed 's/cpython-\([0-9.]*\)-.*/\1/')
    if [[ -z "$version" ]]; then
        # Fallback: use 3.13 if unable to retrieve
        echo "3.13"
    else
        echo "$version"
    fi
}
