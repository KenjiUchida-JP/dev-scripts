#!/usr/bin/env bash
# Input validation functions

# Project name validation
validate_project_name() {
    local name="$1"
    # Empty string check
    if [[ -z "$name" ]]; then
        return 1
    fi
    # Valid characters only (alphanumeric, hyphen, underscore)
    if [[ ! "$name" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]; then
        return 1
    fi
    return 0
}

# Python version format validation
validate_python_version() {
    local version="$1"
    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
        return 1
    fi
    return 0
}
