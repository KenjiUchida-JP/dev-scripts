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

# Build .gitignore for both Python and Node.js
# Comments/blank lines are always kept (so section headers stay intact in
# both templates); actual ignore patterns that appear in both language
# templates (e.g. "tmp/", "*.local") are deduped, keeping the first occurrence.
build_gitignore_combined() {
    local templates_dir="$1"

    {
        cat "${templates_dir}/base.template"
        echo ""
        cat "${templates_dir}/python.template"
        echo ""
        cat "${templates_dir}/nodejs.template"
    } | awk '
        /^[[:space:]]*#/ || /^[[:space:]]*$/ { print; next }
        !seen[$0]++ { print }
    '
}
