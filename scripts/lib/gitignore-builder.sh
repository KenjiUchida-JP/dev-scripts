#!/usr/bin/env bash
# .gitignore composition functions

# Get templates directory
get_templates_dir() {
    local script_dir="$1"
    echo "${script_dir}/../templates/gitignore"
}

# Build .gitignore for single language
build_gitignore_single() {
    local templates_dir="$1"
    local language="$2"  # "python" or "nodejs"

    # Concatenate base + language template
    cat "${templates_dir}/base.template"
    echo ""
    cat "${templates_dir}/${language}.template"
}
