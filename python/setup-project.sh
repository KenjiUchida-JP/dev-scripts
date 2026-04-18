#!/usr/bin/env bash
# ==================================================
# Python Project Setup Script
# Automatic Python environment setup using uv
# ==================================================

set -e

# --------------------------------------------------
# Get script directory (detect remote execution)
# --------------------------------------------------
if [[ "${BASH_SOURCE[0]}" =~ ^/dev/fd/ ]] || [[ "${BASH_SOURCE[0]}" =~ ^/proc/self/fd/ ]]; then
    # Running via curl pipe - download dependencies
    REPO_BASE="https://raw.githubusercontent.com/KenjiUchida-JP/dev-scripts/main"
    TEMP_DIR=$(mktemp -d)
    trap "rm -rf '$TEMP_DIR'" EXIT

    # Download lib files
    mkdir -p "$TEMP_DIR/scripts/lib"
    curl -fsSL "$REPO_BASE/scripts/lib/colors.sh" -o "$TEMP_DIR/scripts/lib/colors.sh"
    curl -fsSL "$REPO_BASE/scripts/lib/validators.sh" -o "$TEMP_DIR/scripts/lib/validators.sh"
    curl -fsSL "$REPO_BASE/scripts/lib/gitignore-builder.sh" -o "$TEMP_DIR/scripts/lib/gitignore-builder.sh"

    # Download template files
    mkdir -p "$TEMP_DIR/templates/gitignore"
    curl -fsSL "$REPO_BASE/templates/gitignore/base.template" -o "$TEMP_DIR/templates/gitignore/base.template"
    curl -fsSL "$REPO_BASE/templates/gitignore/python.template" -o "$TEMP_DIR/templates/gitignore/python.template"

    mkdir -p "$TEMP_DIR/templates/vscode"
    curl -fsSL "$REPO_BASE/templates/vscode/python.settings.json" -o "$TEMP_DIR/templates/vscode/python.settings.json"

    SCRIPT_DIR="$TEMP_DIR"
else
    # Running locally
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# --------------------------------------------------
# Import shared libraries
# --------------------------------------------------
source "${SCRIPT_DIR}/scripts/lib/colors.sh"
source "${SCRIPT_DIR}/scripts/lib/validators.sh"
source "${SCRIPT_DIR}/scripts/lib/gitignore-builder.sh"

# --------------------------------------------------
# Custom header for Python projects
# --------------------------------------------------
print_python_header() {
    echo -e "\n${CYAN}🐍 Python Project Setup${NC}"
    echo "=================================================="
}

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

# Version format validation (alias for library function)
validate_version() {
    validate_python_version "$1"
}

# Get latest Python version
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

# --------------------------------------------------
# .gitignore generation function
# --------------------------------------------------
generate_gitignore() {
    local templates_dir="${SCRIPT_DIR}/templates/gitignore"
    build_gitignore_single "$templates_dir" "python"
}

# --------------------------------------------------
# Append tool configuration to pyproject.toml
# --------------------------------------------------
append_tool_config() {
    local pyproject_file="$1"
    local py_version="$2"
    local major_minor="$3"

    cat >> "$pyproject_file" << TOML_EOF

# --------------------------------------------------
# Tool Configuration
# --------------------------------------------------

[tool.ruff]
target-version = "${py_version}"
line-length = 88

[tool.ruff.lint]
select = ["E", "W", "F", "I", "B", "C4", "UP", "RUF"]

[tool.mypy]
python_version = "${major_minor}"
strict = true

[tool.pytest.ini_options]
testpaths = ["tests"]
TOML_EOF
}

# --------------------------------------------------
# Main process
# --------------------------------------------------
main() {
    print_python_header

    # --------------------------------------------------
    # 1. Fatal collision check (current directory)
    # --------------------------------------------------
    if ! check_python_collisions; then
        print_error "Existing Python project files detected. Aborting to protect them."
        exit 1
    fi

    # --------------------------------------------------
    # 2. Python version input
    # --------------------------------------------------
    print_step "Checking latest available Python version..."
    DEFAULT_PYTHON_VERSION=$(get_latest_python_version)
    print_success "Latest version: $DEFAULT_PYTHON_VERSION"

    while true; do
        echo -ne "${CYAN}🔢 Python version [${DEFAULT_PYTHON_VERSION}]: ${NC}"
        read -r PYTHON_VERSION
        PYTHON_VERSION="${PYTHON_VERSION:-$DEFAULT_PYTHON_VERSION}"
        if validate_version "$PYTHON_VERSION"; then
            break
        else
            print_error "Invalid version format. Example: 3.13, 3.14.2"
        fi
    done

    # --------------------------------------------------
    # 3. Project type selection
    # --------------------------------------------------
    echo -e "${CYAN}📁 Select project type:${NC}"
    echo "  1) app - Application"
    echo "  2) lib - Library"
    while true; do
        echo -ne "${CYAN}Selection [1]: ${NC}"
        read -r PROJECT_TYPE_CHOICE
        PROJECT_TYPE_CHOICE="${PROJECT_TYPE_CHOICE:-1}"
        case "$PROJECT_TYPE_CHOICE" in
            1|app)
                PROJECT_TYPE="app"
                break
                ;;
            2|lib)
                PROJECT_TYPE="lib"
                break
                ;;
            *)
                print_error "Please enter 1 or 2."
                ;;
        esac
    done

    # --------------------------------------------------
    # 4. Development tools confirmation
    # --------------------------------------------------
    echo -ne "${CYAN}🛠️  Install development tools (ruff, mypy, pytest) [Y/n]: ${NC}"
    read -r INSTALL_DEV_TOOLS
    INSTALL_DEV_TOOLS="${INSTALL_DEV_TOOLS:-Y}"

    # --------------------------------------------------
    # Configuration summary
    # --------------------------------------------------
    echo ""
    echo "=================================================="
    echo -e "${YELLOW}Configuration:${NC}"
    echo "  Working directory: $(pwd)"
    echo "  Python version: $PYTHON_VERSION"
    echo "  Project type: $PROJECT_TYPE"
    echo "  Development tools: $([[ "$INSTALL_DEV_TOOLS" =~ ^[Yy]$ ]] && echo "Install" || echo "Skip")"
    echo "=================================================="
    echo ""

    # --------------------------------------------------
    # Detect existing files we should preserve
    # --------------------------------------------------
    local has_existing_readme=0
    local has_existing_gitignore=0
    local has_existing_vscode=0
    local has_existing_git=0
    [[ -f "README.md" ]] && has_existing_readme=1
    [[ -f ".gitignore" ]] && has_existing_gitignore=1
    [[ -f ".vscode/settings.json" ]] && has_existing_vscode=1
    [[ -d ".git" ]] && has_existing_git=1

    # --------------------------------------------------
    # Start setup
    # --------------------------------------------------
    echo -e "${GREEN}✨ Starting setup...${NC}\n"

    # 1. Install Python
    print_step "Installing Python $PYTHON_VERSION..."
    uv python install "$PYTHON_VERSION"
    print_success "Installed Python $PYTHON_VERSION"

    # 2. Initialize project (in current directory; project name auto-derived from dir)
    print_step "Initializing project..."
    local uv_init_args=(--python "$PYTHON_VERSION" "--$PROJECT_TYPE")
    [[ $has_existing_readme -eq 1 ]] && uv_init_args+=(--no-readme)

    # Backup .gitignore in case `uv init` regenerates it
    local gitignore_backup=""
    if [[ $has_existing_gitignore -eq 1 ]]; then
        gitignore_backup=$(mktemp)
        cp .gitignore "$gitignore_backup"
    fi

    uv init "${uv_init_args[@]}"

    # Restore preserved .gitignore
    if [[ $has_existing_gitignore -eq 1 ]]; then
        mv "$gitignore_backup" .gitignore
        print_warning "Existing .gitignore preserved (skipped regeneration)"
    fi
    print_success "Initialized project"

    # 3. Install development tools
    if [[ "$INSTALL_DEV_TOOLS" =~ ^[Yy]$ ]]; then
        print_step "Installing development tools..."
        uv add --dev ruff mypy pytest
        print_success "Installed development tools"
    fi

    # 4. Sync dependencies
    print_step "Syncing dependencies..."
    uv sync
    print_success "Synced dependencies"

    # 5. Generate .gitignore (only when there is no existing one)
    if [[ $has_existing_gitignore -eq 0 ]]; then
        print_step "Generating .gitignore..."
        generate_gitignore > .gitignore
        print_success "Generated .gitignore"
    fi

    # 6. Append tool configuration to pyproject.toml
    if [[ "$INSTALL_DEV_TOOLS" =~ ^[Yy]$ ]]; then
        print_step "Appending tool configuration to pyproject.toml..."
        local py_version
        local major_minor
        py_version=$(get_py_version "$PYTHON_VERSION")
        major_minor=$(get_major_minor "$PYTHON_VERSION")
        append_tool_config "pyproject.toml" "$py_version" "$major_minor"
        print_success "Appended tool configuration"
    fi

    # 7. Create src directory
    print_step "Creating src directory..."
    mkdir -p src
    [[ ! -f "src/__init__.py" ]] && touch src/__init__.py
    print_success "Created src directory"

    # 8. Create tests directory with conftest.py
    if [[ "$INSTALL_DEV_TOOLS" =~ ^[Yy]$ ]]; then
        print_step "Creating tests directory..."
        mkdir -p tests
        [[ ! -f "tests/__init__.py" ]] && touch tests/__init__.py
        if [[ ! -f "tests/conftest.py" ]]; then
            cat > tests/conftest.py << 'CONFTEST_EOF'
"""
pytest configuration file

Add src directory to Python path so that tests can import src modules.
"""

import sys
from pathlib import Path

# Add project root to sys.path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))
CONFTEST_EOF
        fi
        print_success "Created tests directory with conftest.py"
    fi

    # 9. Create .vscode/settings.json (skip if existing)
    if [[ $has_existing_vscode -eq 1 ]]; then
        print_warning "Existing .vscode/settings.json preserved (skipped)"
    else
        print_step "Creating .vscode/settings.json..."
        mkdir -p .vscode
        cp "${SCRIPT_DIR}/templates/vscode/python.settings.json" .vscode/settings.json
        print_success "Created .vscode/settings.json"
    fi

    # 10. Initialize Git (skip if existing)
    if [[ $has_existing_git -eq 1 ]]; then
        print_warning "Existing .git/ preserved (skipped git init)"
    else
        print_step "Initializing Git repository..."
        git init --quiet
        print_success "Initialized Git repository"
    fi

    # --------------------------------------------------
    # Completion message
    # --------------------------------------------------
    echo ""
    echo "=================================================="
    echo -e "${GREEN}🎉 Setup complete!${NC}"
    echo "=================================================="
    echo ""
    echo "Next steps:"
    echo "  uv run python                # Run Python in virtual environment"
    echo "  source .venv/bin/activate    # Or activate the venv directly"
    echo ""
    echo "Useful commands:"
    echo "  uv add <package>      # Add a package"
    echo "  uv run python         # Run Python in virtual environment"
    echo "  uv run pytest         # Run tests"
    echo "  uv run ruff check .   # Run linter"
    echo "  uv run mypy .         # Run type checker"
    echo ""
}

# Run script
main "$@"
