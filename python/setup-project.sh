#!/usr/bin/env bash
# ==================================================
# Python Project Setup Script
# Automatic Python environment setup using uv
# ==================================================

set -e

# --------------------------------------------------
# Color definitions
# --------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --------------------------------------------------
# Helper functions
# --------------------------------------------------
print_header() {
    echo -e "\n${CYAN}🐍 Python Project Setup${NC}"
    echo "=================================================="
}

print_step() {
    echo -e "${BLUE}➜${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
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

# Version format validation
validate_version() {
    local version="$1"
    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
        return 1
    fi
    return 0
}

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

# Get latest Python version
get_latest_python_version() {
    local version
    version=$(uv python list 2>/dev/null | grep -E "^cpython-[0-9]+\.[0-9]+\.[0-9]+-" | grep -v "freethreaded" | head -1 | sed 's/cpython-\([0-9.]*\)-.*/\1/')
    if [[ -z "$version" ]]; then
        # Fallback: use 3.13 if unable to retrieve
        echo "3.13"
    else
        echo "$version"
    fi
}

# --------------------------------------------------
# Get script directory
# --------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- BEGIN GITIGNORE_FUNC ---
# --------------------------------------------------
# .gitignore generation function
# --------------------------------------------------
generate_gitignore() {
    local template_file="${SCRIPT_DIR}/.gitignore.template"
    if [[ -f "$template_file" ]]; then
        cat "$template_file"
    else
        # Fallback for curl execution (auto-generated: build.sh)
        cat << 'GITIGNORE_EOF'
# ==================================================
# Python Project .gitignore Template
# ==================================================

# --------------------------------------------------
# Byte-compiled / Optimized / DLL files
# --------------------------------------------------
__pycache__/
*.py[cod]
*$py.class
*.so

# --------------------------------------------------
# Virtual Environments
# --------------------------------------------------
.venv/
venv/
env/
ENV/

# --------------------------------------------------
# Distribution / Packaging
# --------------------------------------------------
build/
dist/
*.egg-info/
*.egg
wheels/
MANIFEST

# --------------------------------------------------
# Testing / Coverage
# --------------------------------------------------
.pytest_cache/
.coverage
.coverage.*
htmlcov/
.tox/
.nox/

# --------------------------------------------------
# Type Checkers / Linters
# --------------------------------------------------
.mypy_cache/
.ruff_cache/
.pytype/

# --------------------------------------------------
# Environment Variables / Secrets
# --------------------------------------------------
.env
.env.local
.env.*.local
.env.prod
.env.dev
.env.test
*.pem

# --------------------------------------------------
# IDE / Editor
# --------------------------------------------------
.idea/
.cursor/
.claude/
.vscode/
*.swp
*.swo
*~

# --------------------------------------------------
# OS Generated
# --------------------------------------------------
.DS_Store
Thumbs.db

# --------------------------------------------------
# Project Specific
# --------------------------------------------------
docs/
tmp/
GITIGNORE_EOF
    fi
}
# --- END GITIGNORE_FUNC ---

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
    print_header

    # --------------------------------------------------
    # 1. Project name input
    # --------------------------------------------------
    while true; do
        echo -ne "${CYAN}📦 Project name: ${NC}"
        read -r PROJECT_NAME
        if validate_project_name "$PROJECT_NAME"; then
            break
        else
            print_error "Invalid project name. Must start with a letter and contain only alphanumeric characters, hyphens, or underscores."
        fi
    done

    # --------------------------------------------------
    # 2. Setup mode selection (new or existing directory)
    # --------------------------------------------------
    echo -e "${CYAN}📂 Select setup mode:${NC}"
    echo "  1) new      - Create new directory"
    echo "  2) existing - Use existing directory (must be empty)"
    while true; do
        echo -ne "${CYAN}Selection [1]: ${NC}"
        read -r SETUP_MODE_CHOICE
        SETUP_MODE_CHOICE="${SETUP_MODE_CHOICE:-1}"
        case "$SETUP_MODE_CHOICE" in
            1|new)
                SETUP_MODE="new"
                if [[ -d "$PROJECT_NAME" ]]; then
                    print_error "Directory '$PROJECT_NAME' already exists."
                    exit 1
                fi
                break
                ;;
            2|existing)
                SETUP_MODE="existing"
                if [[ ! -d "$PROJECT_NAME" ]]; then
                    print_error "Directory '$PROJECT_NAME' does not exist."
                    exit 1
                fi
                # Check if directory is empty
                if [[ -n "$(ls -A "$PROJECT_NAME" 2>/dev/null)" ]]; then
                    print_error "Directory '$PROJECT_NAME' is not empty. Aborting to prevent accidents."
                    exit 1
                fi
                break
                ;;
            *)
                print_error "Please enter 1 or 2."
                ;;
        esac
    done

    # --------------------------------------------------
    # 3. Python version input
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
    # 4. Project type selection
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
    # 5. Development tools confirmation
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
    echo "  Project name: $PROJECT_NAME"
    echo "  Setup mode: $SETUP_MODE"
    echo "  Python version: $PYTHON_VERSION"
    echo "  Project type: $PROJECT_TYPE"
    echo "  Development tools: $([[ "$INSTALL_DEV_TOOLS" =~ ^[Yy]$ ]] && echo "Install" || echo "Skip")"
    echo "=================================================="
    echo ""

    # --------------------------------------------------
    # Start setup
    # --------------------------------------------------
    echo -e "${GREEN}✨ Starting setup...${NC}\n"

    # 1. Create or use directory
    if [[ "$SETUP_MODE" == "new" ]]; then
        print_step "Creating directory..."
        mkdir -p "$PROJECT_NAME"
        print_success "Created directory '$PROJECT_NAME'"
    else
        print_step "Using existing directory..."
        print_success "Using existing directory '$PROJECT_NAME'"
    fi
    cd "$PROJECT_NAME"

    # 2. Install Python
    print_step "Installing Python $PYTHON_VERSION..."
    uv python install "$PYTHON_VERSION"
    print_success "Installed Python $PYTHON_VERSION"

    # 3. Initialize project
    print_step "Initializing project..."
    uv init --name "$PROJECT_NAME" --python "$PYTHON_VERSION" --"$PROJECT_TYPE"
    print_success "Initialized project"

    # 4. Install development tools
    if [[ "$INSTALL_DEV_TOOLS" =~ ^[Yy]$ ]]; then
        print_step "Installing development tools..."
        uv add --dev ruff mypy pytest
        print_success "Installed development tools"
    fi

    # 5. Sync dependencies
    print_step "Syncing dependencies..."
    uv sync
    print_success "Synced dependencies"

    # 6. Generate .gitignore
    print_step "Generating .gitignore..."
    generate_gitignore > .gitignore
    print_success "Generated .gitignore"

    # 7. Append tool configuration to pyproject.toml
    if [[ "$INSTALL_DEV_TOOLS" =~ ^[Yy]$ ]]; then
        print_step "Appending tool configuration to pyproject.toml..."
        local py_version
        local major_minor
        py_version=$(get_py_version "$PYTHON_VERSION")
        major_minor=$(get_major_minor "$PYTHON_VERSION")
        append_tool_config "pyproject.toml" "$py_version" "$major_minor"
        print_success "Appended tool configuration"
    fi

    # 8. Create src directory
    print_step "Creating src directory..."
    mkdir -p src
    touch src/__init__.py
    print_success "Created src directory"

    # 9. Create tests directory with conftest.py
    if [[ "$INSTALL_DEV_TOOLS" =~ ^[Yy]$ ]]; then
        print_step "Creating tests directory..."
        mkdir -p tests
        touch tests/__init__.py
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
        print_success "Created tests directory with conftest.py"
    fi

    # 9. Create .vscode/settings.json
    print_step "Creating .vscode/settings.json..."
    mkdir -p .vscode
    cat > .vscode/settings.json << VSCODE_EOF
{
    "python.defaultInterpreterPath": "\${workspaceFolder}/.venv/bin/python"
}
VSCODE_EOF
    print_success "Created .vscode/settings.json"

    # 10. Initialize Git
    print_step "Initializing Git repository..."
    git init --quiet
    print_success "Initialized Git repository"

    # --------------------------------------------------
    # Completion message
    # --------------------------------------------------
    echo ""
    echo "=================================================="
    echo -e "${GREEN}🎉 Setup complete!${NC}"
    echo "=================================================="
    echo ""
    echo "Next steps:"
    echo "  cd $PROJECT_NAME"
    echo "  source .venv/bin/activate  # or: uv run python"
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
