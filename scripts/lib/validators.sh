#!/usr/bin/env bash
# Input validation and environment collision detection

# --------------------------------------------------
# Project name validation
# --------------------------------------------------
validate_project_name() {
    local name="$1"
    if [[ -z "$name" ]]; then
        return 1
    fi
    if [[ ! "$name" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]; then
        return 1
    fi
    return 0
}

# --------------------------------------------------
# Python version format validation
# --------------------------------------------------
validate_python_version() {
    local version="$1"
    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
        return 1
    fi
    return 0
}

# --------------------------------------------------
# Collision detection helpers
# Returns 0 if clean, 1 if fatal collisions found.
# Files like README.md / .gitignore / .vscode/settings.json are NOT
# treated as fatal here — caller scripts handle them by skipping
# regeneration so existing content is preserved.
# --------------------------------------------------

check_python_collisions() {
    local found=()
    [[ -d ".venv" ]] && found+=(".venv/")
    [[ -f "pyproject.toml" ]] && found+=("pyproject.toml")
    [[ -f ".python-version" ]] && found+=(".python-version")
    [[ -f "uv.lock" ]] && found+=("uv.lock")

    if [[ ${#found[@]} -gt 0 ]]; then
        print_error "Existing Python environment detected:"
        for item in "${found[@]}"; do
            echo -e "  ${RED}- ${item}${NC}" >&2
        done
        return 1
    fi
    return 0
}

check_node_collisions() {
    local found=()
    [[ -d "node_modules" ]] && found+=("node_modules/")
    [[ -f "package.json" ]] && found+=("package.json")
    [[ -f "package-lock.json" ]] && found+=("package-lock.json")
    [[ -f "pnpm-lock.yaml" ]] && found+=("pnpm-lock.yaml")
    [[ -f "yarn.lock" ]] && found+=("yarn.lock")
    [[ -f "bun.lockb" ]] && found+=("bun.lockb")

    if [[ ${#found[@]} -gt 0 ]]; then
        print_error "Existing Node.js environment detected:"
        for item in "${found[@]}"; do
            echo -e "  ${RED}- ${item}${NC}" >&2
        done
        return 1
    fi
    return 0
}

# Fullstack: backend/ and frontend/ subdirs must be absent or empty.
check_fullstack_collisions() {
    local found=()
    if [[ -d "backend" && -n "$(ls -A backend 2>/dev/null)" ]]; then
        found+=("backend/ (not empty)")
    fi
    if [[ -d "frontend" && -n "$(ls -A frontend 2>/dev/null)" ]]; then
        found+=("frontend/ (not empty)")
    fi

    if [[ ${#found[@]} -gt 0 ]]; then
        print_error "Existing fullstack content detected:"
        for item in "${found[@]}"; do
            echo -e "  ${RED}- ${item}${NC}" >&2
        done
        return 1
    fi
    return 0
}
