#!/usr/bin/env bash
# ==================================================
# Fullstack Project Setup Script
# Automatic fullstack environment setup (Python + Next.js)
# ==================================================

set -e

# --------------------------------------------------
# Get script directory
# --------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --------------------------------------------------
# Import shared libraries
# --------------------------------------------------
source "${SCRIPT_DIR}/../scripts/lib/colors.sh"
source "${SCRIPT_DIR}/../scripts/lib/validators.sh"
source "${SCRIPT_DIR}/../scripts/lib/gitignore-builder.sh"

# --------------------------------------------------
# Custom header for Fullstack projects
# --------------------------------------------------
print_fullstack_header() {
    echo -e "\n${CYAN}🚀 Fullstack Project Setup${NC}"
    echo "=================================================="
}

# --------------------------------------------------
# Main process
# --------------------------------------------------
main() {
    print_fullstack_header

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
    # 2. Check if directory already exists
    # --------------------------------------------------
    if [[ -d "$PROJECT_NAME" ]]; then
        print_error "Directory '$PROJECT_NAME' already exists."
        exit 1
    fi

    # --------------------------------------------------
    # Configuration summary
    # --------------------------------------------------
    echo ""
    echo "=================================================="
    echo -e "${YELLOW}Configuration:${NC}"
    echo "  Project name: $PROJECT_NAME"
    echo "  Stack: Python (backend) + Next.js (frontend)"
    echo "  Structure:"
    echo "    ├── backend/   (Python)"
    echo "    └── frontend/  (Next.js)"
    echo "=================================================="
    echo ""

    # --------------------------------------------------
    # Start setup
    # --------------------------------------------------
    echo -e "${GREEN}✨ Starting setup...${NC}\n"

    # 1. Create root directory
    print_step "Creating project directory..."
    mkdir -p "$PROJECT_NAME"
    cd "$PROJECT_NAME"
    print_success "Created directory '$PROJECT_NAME'"

    # 2. Create subdirectories
    print_step "Creating subdirectories..."
    mkdir -p backend frontend
    print_success "Created backend/ and frontend/ directories"

    # 3. Generate unified .gitignore with path prefixes
    print_step "Generating .gitignore..."
    local templates_dir="${SCRIPT_DIR}/../templates/gitignore"
    if [[ -f "${templates_dir}/base.template" && -f "${templates_dir}/python.template" && -f "${templates_dir}/nextjs.template" ]]; then
        build_gitignore_fullstack "$templates_dir" "python" "nextjs" > .gitignore
        print_success "Generated unified .gitignore"
    else
        print_warning "Template files not found, skipping .gitignore generation"
    fi

    # 4. Generate VS Code settings
    print_step "Creating .vscode/settings.json..."
    mkdir -p .vscode
    local vscode_template="${SCRIPT_DIR}/../templates/vscode/fullstack.settings.json"
    if [[ -f "$vscode_template" ]]; then
        cp "$vscode_template" .vscode/settings.json
        print_success "Created .vscode/settings.json"
    else
        print_warning "VS Code template not found, skipping"
    fi

    # 5. Initialize Git at root
    print_step "Initializing Git repository..."
    git init --quiet
    print_success "Initialized Git repository"

    # 6. Setup backend (Python)
    print_header "Setting up backend (Python)"
    cd backend

    # Check if uv is available
    if ! command -v uv &>/dev/null; then
        print_error "uv is not installed. Please install uv first:"
        echo "  curl -LsSf https://astral.sh/uv/install.sh | sh"
        exit 1
    fi

    # Get latest Python version
    print_step "Checking latest available Python version..."
    local python_version
    python_version=$(uv python list 2>/dev/null | grep -E "^cpython-[0-9]+\.[0-9]+\.[0-9]+-" | grep -v "freethreaded" | head -1 | sed 's/cpython-\([0-9.]*\)-.*/\1/')
    if [[ -z "$python_version" ]]; then
        python_version="3.13"
    fi
    print_success "Using Python $python_version"

    # Install Python
    print_step "Installing Python $python_version..."
    uv python install "$python_version"
    print_success "Installed Python $python_version"

    # Initialize Python project
    print_step "Initializing Python project..."
    uv init --name "${PROJECT_NAME}-backend" --python "$python_version" --app
    print_success "Initialized Python project"

    # Install development tools
    print_step "Installing development tools..."
    uv add --dev ruff mypy pytest
    print_success "Installed development tools"

    # Sync dependencies
    print_step "Syncing dependencies..."
    uv sync
    print_success "Synced dependencies"

    # Create src directory
    print_step "Creating src directory..."
    mkdir -p src
    touch src/__init__.py
    print_success "Created src directory"

    # Create tests directory with conftest.py
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

    # Append tool configuration to pyproject.toml
    print_step "Appending tool configuration to pyproject.toml..."
    local py_version major_minor
    py_version=$(echo "$python_version" | cut -d. -f1,2 | sed 's/\.//')
    py_version="py${py_version}"
    major_minor=$(echo "$python_version" | cut -d. -f1,2)
    cat >> pyproject.toml << TOML_EOF

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
    print_success "Appended tool configuration"

    cd ..
    print_success "Backend setup complete"

    # 7. Setup frontend (Next.js)
    print_header "Setting up frontend (Next.js)"
    cd frontend

    # Check Node.js availability
    if ! command -v node &>/dev/null; then
        print_error "Node.js is not installed. Please install Node.js first."
        exit 1
    fi

    local node_version
    node_version=$(node --version)
    print_success "Using Node.js $node_version"

    # Check package manager
    local pkg_manager="npm"
    if command -v pnpm &>/dev/null; then
        pkg_manager="pnpm"
    elif command -v yarn &>/dev/null; then
        pkg_manager="yarn"
    fi
    print_success "Using package manager: $pkg_manager"

    # Create Next.js project
    print_step "Creating Next.js project..."
    case "$pkg_manager" in
        pnpm)
            pnpm create next-app@latest . --typescript --eslint --tailwind --app --import-alias "@/*"
            ;;
        yarn)
            yarn create next-app . --typescript --eslint --tailwind --app --import-alias "@/*"
            ;;
        *)
            npx create-next-app@latest . --typescript --eslint --tailwind --app --import-alias "@/*"
            ;;
    esac
    print_success "Created Next.js project"

    # Create .prettierrc
    print_step "Creating Prettier config..."
    cat > .prettierrc << 'PRETTIER_EOF'
{
    "semi": true,
    "singleQuote": true,
    "tabWidth": 4,
    "trailingComma": "es5",
    "printWidth": 100
}
PRETTIER_EOF
    print_success "Created .prettierrc"

    cd ..
    print_success "Frontend setup complete"

    # --------------------------------------------------
    # Completion message
    # --------------------------------------------------
    echo ""
    echo "=================================================="
    echo -e "${GREEN}🎉 Fullstack project setup complete!${NC}"
    echo "=================================================="
    echo ""
    echo "Project structure:"
    echo "  $PROJECT_NAME/"
    echo "  ├── backend/   (Python with uv)"
    echo "  └── frontend/  (Next.js with $pkg_manager)"
    echo ""
    echo "Next steps:"
    echo "  cd $PROJECT_NAME"
    echo ""
    echo "Backend commands (from backend/ directory):"
    echo "  uv add <package>      # Add a package"
    echo "  uv run python         # Run Python"
    echo "  uv run pytest         # Run tests"
    echo "  uv run ruff check .   # Run linter"
    echo ""
    echo "Frontend commands (from frontend/ directory):"
    echo "  $pkg_manager install  # Install dependencies"
    echo "  $pkg_manager dev      # Start dev server"
    echo "  $pkg_manager build    # Build for production"
    echo ""
}

# Run script
main "$@"
