#!/usr/bin/env bash
# ==================================================
# Fullstack Project Setup Script
# Automatic fullstack environment setup (Python + Next.js)
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
    curl -fsSL "$REPO_BASE/templates/gitignore/nextjs.template" -o "$TEMP_DIR/templates/gitignore/nextjs.template"

    mkdir -p "$TEMP_DIR/templates/vscode"
    curl -fsSL "$REPO_BASE/templates/vscode/fullstack.settings.json" -o "$TEMP_DIR/templates/vscode/fullstack.settings.json"

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
# Custom header for Fullstack projects
# --------------------------------------------------
print_fullstack_header() {
    echo -e "\n${CYAN}🚀 Fullstack Project Setup${NC}"
    echo "=================================================="
}

# --------------------------------------------------
# Python helper functions (from python/setup-project.sh)
# --------------------------------------------------

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
# Node.js helper functions (from nextjs/setup-project.sh)
# --------------------------------------------------

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Load nvm if available
load_nvm() {
    # nvm is a shell function, not a binary, so we need to source it
    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
    if [[ -s "$NVM_DIR/nvm.sh" ]]; then
        source "$NVM_DIR/nvm.sh"
        return 0
    elif [[ -s "/usr/local/opt/nvm/nvm.sh" ]]; then
        # macOS Homebrew location
        source "/usr/local/opt/nvm/nvm.sh"
        return 0
    elif [[ -s "/opt/homebrew/opt/nvm/nvm.sh" ]]; then
        # macOS Apple Silicon Homebrew location
        source "/opt/homebrew/opt/nvm/nvm.sh"
        return 0
    fi
    return 1
}

# Check if nvm is available
nvm_available() {
    type nvm &>/dev/null
}

# Get installed Node versions via nvm
get_nvm_versions() {
    nvm ls --no-colors 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | sort -V | uniq
}

# Get latest LTS version available
get_nvm_lts_version() {
    nvm ls-remote --lts --no-colors 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | tail -1
}

# Check if fnm is available
fnm_available() {
    command -v fnm &>/dev/null
}

# Get installed Node versions via fnm
get_fnm_versions() {
    fnm list 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | sort -V | uniq
}

# Get latest LTS version available via fnm
get_fnm_lts_version() {
    fnm ls-remote --lts 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | tail -1
}

# --------------------------------------------------
# Next.js version helper functions
# --------------------------------------------------

# Get latest stable Next.js version
get_latest_nextjs_version() {
    local version
    version=$(npm view next version 2>/dev/null)
    if [[ -z "$version" ]]; then
        # Fallback if unable to retrieve
        echo "latest"
    else
        echo "$version"
    fi
}

# --------------------------------------------------
# .env.example generation function
# --------------------------------------------------
generate_env_example() {
    cat << 'ENV_EOF'
# ==================================================
# Environment Variables
# ==================================================
# Copy this file to .env.local and fill in your values
# NEVER commit .env.local to version control

# --------------------------------------------------
# Application
# --------------------------------------------------
# NEXT_PUBLIC_APP_URL=http://localhost:3000

# --------------------------------------------------
# Database (Example)
# --------------------------------------------------
# DATABASE_URL=

# --------------------------------------------------
# Authentication (Example)
# --------------------------------------------------
# NEXTAUTH_SECRET=
# NEXTAUTH_URL=http://localhost:3000
ENV_EOF
}

# --------------------------------------------------
# Prettier config generation function
# --------------------------------------------------
generate_prettier_config() {
    cat << 'PRETTIER_EOF'
{
    "semi": true,
    "singleQuote": true,
    "tabWidth": 4,
    "trailingComma": "es5",
    "printWidth": 100
}
PRETTIER_EOF
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
        if validate_python_version "$PYTHON_VERSION"; then
            break
        else
            print_error "Invalid version format. Example: 3.13, 3.14.2"
        fi
    done

    # --------------------------------------------------
    # 4. Python project type selection
    # --------------------------------------------------
    echo -e "${CYAN}📁 Select backend project type:${NC}"
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
    # 5. Python development tools confirmation
    # --------------------------------------------------
    echo -ne "${CYAN}🛠️  Install Python development tools (ruff, mypy, pytest) [Y/n]: ${NC}"
    read -r INSTALL_PY_DEV_TOOLS
    INSTALL_PY_DEV_TOOLS="${INSTALL_PY_DEV_TOOLS:-Y}"

    # --------------------------------------------------
    # 6. Check prerequisites and Node.js version managers
    # --------------------------------------------------
    print_step "Checking Node.js prerequisites..."

    # Detect version manager: fnm > nvm > system
    VERSION_MANAGER="none"
    SELECTED_NODE_VERSION=""

    if fnm_available; then
        VERSION_MANAGER="fnm"
        print_success "fnm detected"
    elif load_nvm && nvm_available; then
        VERSION_MANAGER="nvm"
        print_success "nvm detected"
    fi

    if ! command_exists node && [[ "$VERSION_MANAGER" == "none" ]]; then
        print_error "Node.js is not installed. Please install Node.js, fnm, or nvm first."
        exit 1
    fi

    # --------------------------------------------------
    # 7. Node.js version selection (if version manager available)
    # --------------------------------------------------
    if [[ "$VERSION_MANAGER" != "none" ]]; then
        echo -e "${CYAN}🔢 Select Node.js version (using ${VERSION_MANAGER}):${NC}"

        # Get installed versions based on version manager
        if [[ "$VERSION_MANAGER" == "fnm" ]]; then
            INSTALLED_VERSIONS=($(get_fnm_versions))
        else
            INSTALLED_VERSIONS=($(get_nvm_versions))
        fi

        if [[ ${#INSTALLED_VERSIONS[@]} -gt 0 ]]; then
            echo "  Installed versions:"
            local i=1
            for ver in "${INSTALLED_VERSIONS[@]}"; do
                echo "    $i) $ver"
                ((i++))
            done
            echo "    $i) Install new version"
            INSTALL_NEW_OPTION=$i

            while true; do
                echo -ne "${CYAN}Selection [1]: ${NC}"
                read -r NODE_VERSION_CHOICE
                NODE_VERSION_CHOICE="${NODE_VERSION_CHOICE:-1}"

                if [[ "$NODE_VERSION_CHOICE" =~ ^[0-9]+$ ]]; then
                    if [[ "$NODE_VERSION_CHOICE" -ge 1 && "$NODE_VERSION_CHOICE" -lt "$INSTALL_NEW_OPTION" ]]; then
                        SELECTED_NODE_VERSION="${INSTALLED_VERSIONS[$((NODE_VERSION_CHOICE-1))]}"
                        break
                    elif [[ "$NODE_VERSION_CHOICE" -eq "$INSTALL_NEW_OPTION" ]]; then
                        # Install new version
                        print_step "Fetching available LTS version..."
                        if [[ "$VERSION_MANAGER" == "fnm" ]]; then
                            LTS_VERSION=$(get_fnm_lts_version)
                        else
                            LTS_VERSION=$(get_nvm_lts_version)
                        fi
                        echo -ne "${CYAN}Enter version to install [${LTS_VERSION}]: ${NC}"
                        read -r NEW_VERSION
                        NEW_VERSION="${NEW_VERSION:-$LTS_VERSION}"

                        print_step "Installing Node.js ${NEW_VERSION}..."
                        if [[ "$VERSION_MANAGER" == "fnm" ]]; then
                            fnm install "$NEW_VERSION"
                        else
                            nvm install "$NEW_VERSION"
                        fi
                        SELECTED_NODE_VERSION="$NEW_VERSION"
                        break
                    fi
                fi
                print_error "Invalid selection."
            done
        else
            # No versions installed
            print_warning "No Node.js versions installed via ${VERSION_MANAGER}."
            print_step "Fetching available LTS version..."
            if [[ "$VERSION_MANAGER" == "fnm" ]]; then
                LTS_VERSION=$(get_fnm_lts_version)
            else
                LTS_VERSION=$(get_nvm_lts_version)
            fi
            echo -ne "${CYAN}Enter version to install [${LTS_VERSION}]: ${NC}"
            read -r NEW_VERSION
            NEW_VERSION="${NEW_VERSION:-$LTS_VERSION}"

            print_step "Installing Node.js ${NEW_VERSION}..."
            if [[ "$VERSION_MANAGER" == "fnm" ]]; then
                fnm install "$NEW_VERSION"
            else
                nvm install "$NEW_VERSION"
            fi
            SELECTED_NODE_VERSION="$NEW_VERSION"
        fi

        # Switch to selected version
        print_step "Switching to Node.js ${SELECTED_NODE_VERSION}..."
        if [[ "$VERSION_MANAGER" == "fnm" ]]; then
            fnm use "$SELECTED_NODE_VERSION"
        else
            nvm use "$SELECTED_NODE_VERSION"
        fi
        print_success "Using Node.js ${SELECTED_NODE_VERSION}"
    else
        # No version manager available, use system Node
        if ! command_exists npm; then
            print_error "npm is not installed. Please install npm first."
            exit 1
        fi
        SELECTED_NODE_VERSION=$(node -v)
        print_success "Node.js ${SELECTED_NODE_VERSION} found (system)"
    fi

    # --------------------------------------------------
    # 8. Next.js version input
    # --------------------------------------------------
    print_step "Checking latest stable Next.js version..."
    DEFAULT_NEXTJS_VERSION=$(get_latest_nextjs_version)
    print_success "Latest version: $DEFAULT_NEXTJS_VERSION"

    while true; do
        echo -ne "${CYAN}⚡ Next.js version [${DEFAULT_NEXTJS_VERSION}]: ${NC}"
        read -r NEXTJS_VERSION
        NEXTJS_VERSION="${NEXTJS_VERSION:-$DEFAULT_NEXTJS_VERSION}"
        # Accept any non-empty string (version number or "latest")
        if [[ -n "$NEXTJS_VERSION" ]]; then
            break
        else
            print_error "Version cannot be empty"
        fi
    done

    # --------------------------------------------------
    # 9. Package manager selection
    # --------------------------------------------------
    echo -e "${CYAN}📦 Select package manager:${NC}"
    echo "  1) npm"
    echo "  2) pnpm"
    echo "  3) yarn"
    echo "  4) bun"
    while true; do
        echo -ne "${CYAN}Selection [1]: ${NC}"
        read -r PKG_MANAGER_CHOICE
        PKG_MANAGER_CHOICE="${PKG_MANAGER_CHOICE:-1}"
        case "$PKG_MANAGER_CHOICE" in
            1|npm)
                PKG_MANAGER="npm"
                break
                ;;
            2|pnpm)
                if ! command_exists pnpm; then
                    print_error "pnpm is not installed. Run: npm install -g pnpm"
                    continue
                fi
                PKG_MANAGER="pnpm"
                break
                ;;
            3|yarn)
                if ! command_exists yarn; then
                    print_error "yarn is not installed. Run: npm install -g yarn"
                    continue
                fi
                PKG_MANAGER="yarn"
                break
                ;;
            4|bun)
                if ! command_exists bun; then
                    print_error "bun is not installed. See: https://bun.sh"
                    continue
                fi
                PKG_MANAGER="bun"
                break
                ;;
            *)
                print_error "Please enter 1, 2, 3, or 4."
                ;;
        esac
    done

    # --------------------------------------------------
    # 10. Install Prettier
    # --------------------------------------------------
    echo -ne "${CYAN}🎨 Install Prettier [Y/n]: ${NC}"
    read -r INSTALL_PRETTIER
    INSTALL_PRETTIER="${INSTALL_PRETTIER:-Y}"

    # --------------------------------------------------
    # Configuration summary
    # --------------------------------------------------
    echo ""
    echo "=================================================="
    echo -e "${YELLOW}Configuration:${NC}"
    echo "  Project name: $PROJECT_NAME"
    echo "  Setup mode: $SETUP_MODE"
    echo "  Stack: Python (backend) + Next.js (frontend)"
    echo "  Structure:"
    echo "    ├── backend/   (Python)"
    echo "    └── frontend/  (Next.js)"
    echo ""
    echo "Backend (Python):"
    echo "  Python version: $PYTHON_VERSION"
    echo "  Project type: $PROJECT_TYPE"
    echo "  Development tools: $([[ "$INSTALL_PY_DEV_TOOLS" =~ ^[Yy]$ ]] && echo "Install" || echo "Skip")"
    echo ""
    echo "Frontend (Next.js):"
    echo "  Node.js version: $SELECTED_NODE_VERSION"
    echo "  Next.js version: $NEXTJS_VERSION"
    echo "  Package manager: $PKG_MANAGER"
    echo "  TypeScript: Yes (recommended)"
    echo "  ESLint: Yes (recommended)"
    echo "  Tailwind CSS: Yes (recommended)"
    echo "  src/ directory: Yes (recommended)"
    echo "  App Router: Yes (recommended)"
    echo "  Prettier: $([[ "$INSTALL_PRETTIER" =~ ^[Yy]$ ]] && echo "Yes" || echo "No")"
    echo "=================================================="
    echo ""

    # --------------------------------------------------
    # Start setup
    # --------------------------------------------------
    echo -e "${GREEN}✨ Starting setup...${NC}\n"

    # 1. Create or use root directory
    if [[ "$SETUP_MODE" == "new" ]]; then
        print_step "Creating project directory..."
        mkdir -p "$PROJECT_NAME"
        print_success "Created directory '$PROJECT_NAME'"
    else
        print_step "Using existing directory..."
        print_success "Using existing directory '$PROJECT_NAME'"
    fi
    cd "$PROJECT_NAME"

    # 2. Create subdirectories
    print_step "Creating subdirectories..."
    mkdir -p backend frontend
    print_success "Created backend/ and frontend/ directories"

    # 3. Generate unified .gitignore with path prefixes
    print_step "Generating .gitignore..."
    local templates_dir="${SCRIPT_DIR}/templates/gitignore"
    if [[ -f "${templates_dir}/base.template" && -f "${templates_dir}/python.template" && -f "${templates_dir}/nextjs.template" ]]; then
        build_gitignore_fullstack "$templates_dir" "python" "nextjs" > .gitignore
        print_success "Generated unified .gitignore"
    else
        print_warning "Template files not found, skipping .gitignore generation"
    fi

    # 4. Generate VS Code settings
    print_step "Creating .vscode/settings.json..."
    mkdir -p .vscode
    local vscode_template="${SCRIPT_DIR}/templates/vscode/fullstack.settings.json"
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

    # Install Python
    print_step "Installing Python $PYTHON_VERSION..."
    uv python install "$PYTHON_VERSION"
    print_success "Installed Python $PYTHON_VERSION"

    # Initialize Python project
    print_step "Initializing Python project..."
    uv init --name "${PROJECT_NAME}-backend" --python "$PYTHON_VERSION" --"$PROJECT_TYPE"
    print_success "Initialized Python project"

    # Install development tools
    if [[ "$INSTALL_PY_DEV_TOOLS" =~ ^[Yy]$ ]]; then
        print_step "Installing development tools..."
        uv add --dev ruff mypy pytest
        print_success "Installed development tools"
    fi

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
    if [[ "$INSTALL_PY_DEV_TOOLS" =~ ^[Yy]$ ]]; then
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

    # Append tool configuration to pyproject.toml
    if [[ "$INSTALL_PY_DEV_TOOLS" =~ ^[Yy]$ ]]; then
        print_step "Appending tool configuration to pyproject.toml..."
        local py_version major_minor
        py_version=$(get_py_version "$PYTHON_VERSION")
        major_minor=$(get_major_minor "$PYTHON_VERSION")
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
    fi

    cd ..
    print_success "Backend setup complete"

    # 7. Setup frontend (Next.js)
    print_header "Setting up frontend (Next.js)"
    cd frontend

    # Determine package manager flag for create-next-app
    local pkg_flag=""
    case "$PKG_MANAGER" in
        npm)
            pkg_flag=""
            ;;
        pnpm)
            pkg_flag="--use-pnpm"
            ;;
        yarn)
            pkg_flag="--use-yarn"
            ;;
        bun)
            pkg_flag="--use-bun"
            ;;
    esac

    # Create Next.js project
    print_step "Creating Next.js project with recommended settings..."

    # Determine create-next-app version to use
    if [[ "$NEXTJS_VERSION" == "latest" ]]; then
        CNA_VERSION="latest"
    else
        # Use specific Next.js version with corresponding create-next-app
        CNA_VERSION="$NEXTJS_VERSION"
    fi

    npx create-next-app@${CNA_VERSION} . \
        --typescript \
        --eslint \
        --tailwind \
        --src-dir \
        --app \
        --import-alias "@/*" \
        $pkg_flag
    print_success "Created Next.js project (Next.js ${NEXTJS_VERSION})"

    # Install Prettier
    if [[ "$INSTALL_PRETTIER" =~ ^[Yy]$ ]]; then
        print_step "Installing Prettier..."
        case "$PKG_MANAGER" in
            npm)
                npm install --save-dev prettier eslint-config-prettier
                ;;
            pnpm)
                pnpm add -D prettier eslint-config-prettier
                ;;
            yarn)
                yarn add -D prettier eslint-config-prettier
                ;;
            bun)
                bun add -D prettier eslint-config-prettier
                ;;
        esac
        print_success "Installed Prettier"

        # Generate .prettierrc
        print_step "Generating .prettierrc..."
        generate_prettier_config > .prettierrc
        print_success "Generated .prettierrc"

        # Update ESLint config to include Prettier
        print_step "Updating ESLint config..."
        if [[ -f "eslint.config.mjs" ]]; then
            # Next.js 15+ uses eslint.config.mjs (flat config)
            cat > eslint.config.mjs << 'ESLINT_EOF'
import { dirname } from "path";
import { fileURLToPath } from "url";
import { FlatCompat } from "@eslint/eslintrc";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const compat = new FlatCompat({
  baseDirectory: __dirname,
});

const eslintConfig = [
  ...compat.extends("next/core-web-vitals", "next/typescript", "prettier"),
];

export default eslintConfig;
ESLINT_EOF
        elif [[ -f ".eslintrc.json" ]]; then
            # Legacy config format
            cat > .eslintrc.json << 'ESLINT_EOF'
{
    "extends": ["next/core-web-vitals", "next/typescript", "prettier"]
}
ESLINT_EOF
        fi
        print_success "Updated ESLint config"
    fi

    # Generate .env.example
    print_step "Generating .env.example..."
    generate_env_example > .env.example
    print_success "Generated .env.example"

    # Generate .nvmrc / .node-version (if version manager was used)
    if [[ "$VERSION_MANAGER" != "none" ]]; then
        print_step "Generating .nvmrc and .node-version..."
        # .nvmrc for nvm compatibility
        echo "$SELECTED_NODE_VERSION" > .nvmrc
        # .node-version for fnm and other tools
        echo "$SELECTED_NODE_VERSION" > .node-version
        print_success "Generated .nvmrc and .node-version"
    fi

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
    echo "  ├── backend/   (Python $PYTHON_VERSION with uv)"
    echo "  └── frontend/  (Next.js with $PKG_MANAGER)"
    echo ""
    echo "Next steps:"
    echo "  cd $PROJECT_NAME"
    if [[ "$VERSION_MANAGER" == "fnm" ]]; then
        echo "  fnm use                # Use project's Node version (in frontend/)"
    elif [[ "$VERSION_MANAGER" == "nvm" ]]; then
        echo "  nvm use                # Use project's Node version (in frontend/)"
    fi
    echo ""
    echo "Backend commands (from backend/ directory):"
    echo "  uv add <package>      # Add a package"
    echo "  uv run python         # Run Python"
    if [[ "$INSTALL_PY_DEV_TOOLS" =~ ^[Yy]$ ]]; then
        echo "  uv run pytest         # Run tests"
        echo "  uv run ruff check .   # Run linter"
        echo "  uv run mypy .         # Run type checker"
    fi
    echo ""
    echo "Frontend commands (from frontend/ directory):"
    case "$PKG_MANAGER" in
        npm)
            echo "  npm run dev       # Start development server"
            echo "  npm run build     # Build for production"
            echo "  npm run start     # Start production server"
            echo "  npm run lint      # Run ESLint"
            ;;
        pnpm)
            echo "  pnpm dev          # Start development server"
            echo "  pnpm build        # Build for production"
            echo "  pnpm start        # Start production server"
            echo "  pnpm lint         # Run ESLint"
            ;;
        yarn)
            echo "  yarn dev          # Start development server"
            echo "  yarn build        # Build for production"
            echo "  yarn start        # Start production server"
            echo "  yarn lint         # Run ESLint"
            ;;
        bun)
            echo "  bun run dev       # Start development server"
            echo "  bun run build     # Build for production"
            echo "  bun run start     # Start production server"
            echo "  bun run lint      # Run ESLint"
            ;;
    esac
    echo ""
    echo "Open in browser: http://localhost:3000 (frontend)"
    echo ""
}

# Run script
main "$@"
