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
    local language="$2"  # "python" or "nextjs"

    # Concatenate base + language template
    cat "${templates_dir}/base.template"
    echo ""
    cat "${templates_dir}/${language}.template"
}

# Build .gitignore for fullstack
build_gitignore_fullstack() {
    local templates_dir="$1"
    shift
    local languages=("$@")  # Array of languages

    # Start with base
    cat "${templates_dir}/base.template"

    # Add each language with path prefix
    for lang in "${languages[@]}"; do
        local subdir=""
        case "$lang" in
            python)
                subdir="backend"
                ;;
            nextjs)
                subdir="frontend"
                ;;
        esac

        echo ""
        echo "# --------------------------------------------------"
        echo "# $(echo ${subdir} | sed 's/.*/\u&/') ($lang)"
        echo "# --------------------------------------------------"

        # Add path prefix to each line (skip comments and empty lines)
        sed "s|^[^#]|${subdir}/&|" "${templates_dir}/${lang}.template"
    done
}
