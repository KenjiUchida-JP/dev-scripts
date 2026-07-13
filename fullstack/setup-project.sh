#!/usr/bin/env bash
# ==================================================
# Full-stack Project Setup Script
# Sets up both a Python (uv) and a Node.js + TypeScript
# runtime environment in the same directory, with merged
# .gitignore / .vscode/settings.json / CLAUDE.md.temp
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
    curl -fsSL "$REPO_BASE/scripts/lib/python-version.sh" -o "$TEMP_DIR/scripts/lib/python-version.sh"
    curl -fsSL "$REPO_BASE/scripts/lib/node-version.sh" -o "$TEMP_DIR/scripts/lib/node-version.sh"

    # Download template files
    mkdir -p "$TEMP_DIR/templates/gitignore"
    curl -fsSL "$REPO_BASE/templates/gitignore/base.template" -o "$TEMP_DIR/templates/gitignore/base.template"
    curl -fsSL "$REPO_BASE/templates/gitignore/python.template" -o "$TEMP_DIR/templates/gitignore/python.template"
    curl -fsSL "$REPO_BASE/templates/gitignore/nodejs.template" -o "$TEMP_DIR/templates/gitignore/nodejs.template"

    mkdir -p "$TEMP_DIR/templates/vscode"
    curl -fsSL "$REPO_BASE/templates/vscode/fullstack.settings.json" -o "$TEMP_DIR/templates/vscode/fullstack.settings.json"

    mkdir -p "$TEMP_DIR/templates/claude"
    curl -fsSL "$REPO_BASE/templates/claude/fullstack.template.md" -o "$TEMP_DIR/templates/claude/fullstack.template.md"

    SCRIPT_DIR="$TEMP_DIR"
else
    # Running locally (repo root, one level up from this script's directory)
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

# --------------------------------------------------
# Import shared libraries
# --------------------------------------------------
source "${SCRIPT_DIR}/scripts/lib/colors.sh"
source "${SCRIPT_DIR}/scripts/lib/validators.sh"
source "${SCRIPT_DIR}/scripts/lib/gitignore-builder.sh"
source "${SCRIPT_DIR}/scripts/lib/python-version.sh"
source "${SCRIPT_DIR}/scripts/lib/node-version.sh"

# --------------------------------------------------
# Custom header
# --------------------------------------------------
print_fullstack_header() {
    echo -e "\n${CYAN}🐍⬢ Full-stack (Python + Node.js) Project Setup${NC}"
    echo "=================================================="
}

# --------------------------------------------------
# .gitignore generation function (merged)
# --------------------------------------------------
generate_gitignore() {
    local templates_dir="${SCRIPT_DIR}/templates/gitignore"
    build_gitignore_combined "$templates_dir"
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
# Generate tsconfig.json
# --------------------------------------------------
generate_tsconfig() {
    cat << 'TSCONFIG_EOF'
{
    "compilerOptions": {
        "target": "ES2022",
        "module": "NodeNext",
        "moduleResolution": "NodeNext",
        "lib": ["ES2022"],
        "outDir": "dist",
        "rootDir": "src",
        "strict": true,
        "esModuleInterop": true,
        "skipLibCheck": true,
        "forceConsistentCasingInFileNames": true,
        "resolveJsonModule": true
    },
    "include": ["src"]
}
TSCONFIG_EOF
}

# --------------------------------------------------
# Generate Prettier config
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
# Generate ESLint flat config
# --------------------------------------------------
generate_eslint_config() {
    cat << 'ESLINT_EOF'
// @ts-check
import eslint from "@eslint/js";
import tseslint from "typescript-eslint";
import eslintConfigPrettier from "eslint-config-prettier";

export default tseslint.config(
    eslint.configs.recommended,
    ...tseslint.configs.recommended,
    eslintConfigPrettier,
    {
        ignores: ["dist/"],
    }
);
ESLINT_EOF
}

# --------------------------------------------------
# Generate src/index.ts stub
# --------------------------------------------------
generate_index_ts() {
    cat << 'INDEX_EOF'
export function main(): void {
    console.log("Hello from Node.js!");
}

main();
INDEX_EOF
}

# --------------------------------------------------
# Main process
# --------------------------------------------------
main() {
    print_fullstack_header

    # --------------------------------------------------
    # 1. Fatal collision check (current directory)
    # --------------------------------------------------
    local collisions_ok=1
    check_python_collisions || collisions_ok=0
    check_node_collisions || collisions_ok=0
    if [[ $collisions_ok -eq 0 ]]; then
        print_error "Existing Python and/or Node.js project files detected. Aborting to protect them."
        exit 1
    fi

    # ==================================================
    # Python configuration
    # ==================================================
    echo -e "\n${YELLOW}--- Python configuration ---${NC}"

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

    echo -e "${CYAN}📁 Select Python project type:${NC}"
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

    echo -ne "${CYAN}🛠️  Install Python dev tools (ruff, mypy, pytest) [Y/n]: ${NC}"
    read -r INSTALL_PY_DEV_TOOLS
    INSTALL_PY_DEV_TOOLS="${INSTALL_PY_DEV_TOOLS:-Y}"

    # ==================================================
    # Node.js configuration
    # ==================================================
    echo -e "\n${YELLOW}--- Node.js configuration ---${NC}"

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

    if [[ "$VERSION_MANAGER" != "none" ]]; then
        echo -e "${CYAN}🔢 Select Node.js version (using ${VERSION_MANAGER}):${NC}"

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

        print_step "Switching to Node.js ${SELECTED_NODE_VERSION}..."
        if [[ "$VERSION_MANAGER" == "fnm" ]]; then
            fnm use "$SELECTED_NODE_VERSION"
        else
            nvm use "$SELECTED_NODE_VERSION"
        fi
        print_success "Using Node.js ${SELECTED_NODE_VERSION}"
    else
        if ! command_exists npm; then
            print_error "npm is not installed. Please install npm first."
            exit 1
        fi
        SELECTED_NODE_VERSION=$(node -v)
        print_success "Node.js ${SELECTED_NODE_VERSION} found (system)"
    fi

    DEFAULT_PKG_CHOICE=2
    command_exists pnpm && DEFAULT_PKG_CHOICE=1

    echo -e "${CYAN}📦 Select package manager:${NC}"
    echo "  1) pnpm (recommended)"
    echo "  2) npm"
    echo "  3) yarn"
    echo "  4) bun"
    while true; do
        echo -ne "${CYAN}Selection [${DEFAULT_PKG_CHOICE}]: ${NC}"
        read -r PKG_MANAGER_CHOICE
        PKG_MANAGER_CHOICE="${PKG_MANAGER_CHOICE:-$DEFAULT_PKG_CHOICE}"
        case "$PKG_MANAGER_CHOICE" in
            1|pnpm)
                if ! command_exists pnpm; then
                    print_error "pnpm is not installed. Install it with: corepack enable"
                    continue
                fi
                PKG_MANAGER="pnpm"
                break
                ;;
            2|npm)
                PKG_MANAGER="npm"
                break
                ;;
            3|yarn)
                if ! command_exists yarn; then
                    print_error "yarn is not installed. Install it with: corepack enable"
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

    echo -ne "${CYAN}🛠️  Install Node.js dev tools (eslint, prettier, vitest) [Y/n]: ${NC}"
    read -r INSTALL_NODE_DEV_TOOLS
    INSTALL_NODE_DEV_TOOLS="${INSTALL_NODE_DEV_TOOLS:-Y}"

    # --------------------------------------------------
    # Configuration summary
    # --------------------------------------------------
    echo ""
    echo "=================================================="
    echo -e "${YELLOW}Configuration:${NC}"
    echo "  Working directory: $(pwd)"
    echo "  Python version: $PYTHON_VERSION"
    echo "  Python project type: $PROJECT_TYPE"
    echo "  Python dev tools: $([[ "$INSTALL_PY_DEV_TOOLS" =~ ^[Yy]$ ]] && echo "Install" || echo "Skip")"
    echo "  Node.js version: $SELECTED_NODE_VERSION"
    echo "  Package manager: $PKG_MANAGER"
    echo "  Node.js dev tools: $([[ "$INSTALL_NODE_DEV_TOOLS" =~ ^[Yy]$ ]] && echo "Install (eslint, prettier, vitest)" || echo "Skip")"
    echo "=================================================="
    echo ""

    # --------------------------------------------------
    # Detect existing files we should preserve
    # --------------------------------------------------
    local has_existing_readme=0
    local has_existing_gitignore=0
    local has_existing_vscode=0
    local has_existing_git=0
    local has_existing_claude_md=0
    [[ -f "README.md" ]] && has_existing_readme=1
    [[ -f ".gitignore" ]] && has_existing_gitignore=1
    [[ -f ".vscode/settings.json" ]] && has_existing_vscode=1
    [[ -d ".git" ]] && has_existing_git=1
    [[ -f "CLAUDE.md.temp" ]] && has_existing_claude_md=1

    # --------------------------------------------------
    # Start setup
    # --------------------------------------------------
    echo -e "${GREEN}✨ Starting setup...${NC}\n"

    # 1. Install Python
    print_step "Installing Python $PYTHON_VERSION..."
    uv python install "$PYTHON_VERSION"
    print_success "Installed Python $PYTHON_VERSION"

    # 2. Initialize Python project (project name auto-derived from dir)
    print_step "Initializing Python project..."
    local uv_init_args=(--python "$PYTHON_VERSION" "--$PROJECT_TYPE")
    [[ $has_existing_readme -eq 1 ]] && uv_init_args+=(--no-readme)

    # Backup .gitignore in case `uv init` regenerates it
    local gitignore_backup=""
    if [[ $has_existing_gitignore -eq 1 ]]; then
        gitignore_backup=$(mktemp)
        cp .gitignore "$gitignore_backup"
    fi

    uv init "${uv_init_args[@]}"

    if [[ $has_existing_gitignore -eq 1 ]]; then
        mv "$gitignore_backup" .gitignore
        print_warning "Existing .gitignore preserved (skipped regeneration)"
    fi
    print_success "Initialized Python project"

    # 3. Install Python dev tools
    if [[ "$INSTALL_PY_DEV_TOOLS" =~ ^[Yy]$ ]]; then
        print_step "Installing Python dev tools..."
        uv add --dev ruff mypy pytest
        print_success "Installed Python dev tools"
    fi

    # 4. Sync Python dependencies
    print_step "Syncing Python dependencies..."
    uv sync
    print_success "Synced Python dependencies"

    # 5. Append tool configuration to pyproject.toml
    if [[ "$INSTALL_PY_DEV_TOOLS" =~ ^[Yy]$ ]]; then
        print_step "Appending tool configuration to pyproject.toml..."
        local py_version
        local major_minor
        py_version=$(get_py_version "$PYTHON_VERSION")
        major_minor=$(get_major_minor "$PYTHON_VERSION")
        append_tool_config "pyproject.toml" "$py_version" "$major_minor"
        print_success "Appended tool configuration"
    fi

    # 6. Create src directory (shared by Python and Node.js)
    print_step "Creating src directory..."
    mkdir -p src
    [[ ! -f "src/__init__.py" ]] && touch src/__init__.py
    print_success "Created src directory"

    # 7. Create tests directory with conftest.py
    if [[ "$INSTALL_PY_DEV_TOOLS" =~ ^[Yy]$ ]]; then
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

    # 8. Initialize package.json (name auto-derived from current dir by npm)
    print_step "Initializing package.json..."
    npm init -y >/dev/null
    print_success "Initialized package.json"

    # pnpm ignores dependency build scripts by default (supply-chain safety).
    # esbuild (pulled in by tsx) relies on its postinstall to fetch its native
    # binary, so pre-approve it before any install runs the script. As of
    # pnpm 10+, this lives in pnpm-workspace.yaml under "allowBuilds" (a
    # package-name -> boolean map).
    if [[ "$PKG_MANAGER" == "pnpm" ]]; then
        if [[ -f "pnpm-workspace.yaml" ]] && grep -q "^allowBuilds:" pnpm-workspace.yaml; then
            grep -q "esbuild:" pnpm-workspace.yaml || sed -i '/^allowBuilds:/a\  esbuild: true' pnpm-workspace.yaml
        elif [[ -f "pnpm-workspace.yaml" ]]; then
            printf 'allowBuilds:\n  esbuild: true\n' >> pnpm-workspace.yaml
        else
            printf 'allowBuilds:\n  esbuild: true\n' > pnpm-workspace.yaml
        fi
    fi

    # 9. Install TypeScript + tsx (run .ts files directly, no build step needed)
    print_step "Installing TypeScript runtime (typescript, tsx, @types/node)..."
    case "$PKG_MANAGER" in
        npm)  npm install --save-dev "typescript@^5" tsx @types/node ;;
        pnpm) pnpm add -D "typescript@^5" tsx @types/node ;;
        yarn) yarn add -D "typescript@^5" tsx @types/node ;;
        bun)  bun add -D "typescript@^5" tsx @types/node ;;
    esac
    print_success "Installed TypeScript runtime"

    # 10. Generate tsconfig.json
    print_step "Generating tsconfig.json..."
    generate_tsconfig > tsconfig.json
    print_success "Generated tsconfig.json"

    # 11. Add src/index.ts entry stub (src/ already created in step 6)
    [[ ! -f "src/index.ts" ]] && generate_index_ts > src/index.ts

    # 12. Install Node.js dev tools
    if [[ "$INSTALL_NODE_DEV_TOOLS" =~ ^[Yy]$ ]]; then
        print_step "Installing Node.js dev tools..."
        case "$PKG_MANAGER" in
            npm)  npm install --save-dev eslint @eslint/js typescript-eslint prettier eslint-config-prettier vitest ;;
            pnpm) pnpm add -D eslint @eslint/js typescript-eslint prettier eslint-config-prettier vitest ;;
            yarn) yarn add -D eslint @eslint/js typescript-eslint prettier eslint-config-prettier vitest ;;
            bun)  bun add -D eslint @eslint/js typescript-eslint prettier eslint-config-prettier vitest ;;
        esac
        print_success "Installed Node.js dev tools"

        print_step "Generating eslint.config.mjs..."
        generate_eslint_config > eslint.config.mjs
        print_success "Generated eslint.config.mjs"

        print_step "Generating .prettierrc..."
        generate_prettier_config > .prettierrc
        print_success "Generated .prettierrc"
    fi

    # 13. Add npm scripts to package.json
    print_step "Updating package.json..."
    node -e "
        const fs = require('fs');
        const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
        pkg.scripts = pkg.scripts || {};
        pkg.scripts.start = 'tsx src/index.ts';
        pkg.scripts.build = 'tsc';
        pkg.scripts.typecheck = 'tsc --noEmit';
        $( [[ "$INSTALL_NODE_DEV_TOOLS" =~ ^[Yy]$ ]] && echo "
        pkg.scripts.lint = 'eslint .';
        pkg.scripts.format = 'prettier --write .';
        pkg.scripts.test = 'vitest run';
        " )
        $( [[ "$PKG_MANAGER" == "pnpm" || "$PKG_MANAGER" == "yarn" ]] && echo "
        // Pin the package manager so corepack enforces it for anyone on this project
        pkg.packageManager = '${PKG_MANAGER}@' + require('child_process').execSync('${PKG_MANAGER} --version').toString().trim();
        " )
        fs.writeFileSync('package.json', JSON.stringify(pkg, null, 4) + '\n');
    "
    print_success "Updated package.json"

    # 14. Generate .gitignore (merged Python + Node.js; only when there is no existing one)
    if [[ $has_existing_gitignore -eq 0 ]]; then
        print_step "Generating merged .gitignore..."
        generate_gitignore > .gitignore
        print_success "Generated merged .gitignore"
    fi

    # 15. Generate .vscode/settings.json (merged; skip if existing)
    if [[ $has_existing_vscode -eq 1 ]]; then
        print_warning "Existing .vscode/settings.json preserved (skipped)"
    else
        print_step "Generating merged .vscode/settings.json..."
        mkdir -p .vscode
        cp "${SCRIPT_DIR}/templates/vscode/fullstack.settings.json" .vscode/settings.json
        print_success "Generated merged .vscode/settings.json"
    fi

    # 16. Generate .nvmrc / .node-version (if version manager was used)
    if [[ "$VERSION_MANAGER" != "none" ]]; then
        print_step "Generating .nvmrc and .node-version..."
        echo "$SELECTED_NODE_VERSION" > .nvmrc
        echo "$SELECTED_NODE_VERSION" > .node-version
        print_success "Generated .nvmrc and .node-version"
    fi

    # 17. Create CLAUDE.md.temp (merged; skip if existing)
    if [[ $has_existing_claude_md -eq 1 ]]; then
        print_warning "Existing CLAUDE.md.temp preserved (skipped)"
    else
        print_step "Creating merged CLAUDE.md.temp..."
        cp "${SCRIPT_DIR}/templates/claude/fullstack.template.md" CLAUDE.md.temp
        print_success "Created merged CLAUDE.md.temp"
    fi

    # 18. Initialize Git (skip if existing)
    if [[ $has_existing_git -eq 1 ]]; then
        print_warning "Existing .git/ preserved (skipped git init)"
    else
        print_step "Initializing Git repository..."
        git init --quiet -b main
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
    echo "Next steps (Python):"
    echo "  uv run python                # Run Python in virtual environment"
    echo "  source .venv/bin/activate    # Or activate the venv directly"
    echo ""
    echo "Next steps (Node.js):"
    if [[ "$VERSION_MANAGER" == "fnm" ]]; then
        echo "  fnm use                # Use project's Node version"
    elif [[ "$VERSION_MANAGER" == "nvm" ]]; then
        echo "  nvm use                # Use project's Node version"
    fi
    echo "  $PKG_MANAGER run start"
    echo ""
    echo "Useful commands (Python):"
    echo "  uv add <package>      # Add a package"
    echo "  uv run pytest         # Run tests"
    echo "  uv run ruff check .   # Run linter"
    echo "  uv run mypy .         # Run type checker"
    echo ""
    echo "Useful commands (Node.js):"
    echo "  $PKG_MANAGER run start       # Run src/index.ts directly (tsx)"
    echo "  $PKG_MANAGER run typecheck   # Type-check without emitting"
    echo "  $PKG_MANAGER run build       # Compile to dist/"
    if [[ "$INSTALL_NODE_DEV_TOOLS" =~ ^[Yy]$ ]]; then
        echo "  $PKG_MANAGER run lint        # Run ESLint"
        echo "  $PKG_MANAGER run format      # Run Prettier"
        echo "  $PKG_MANAGER run test        # Run tests (vitest)"
    fi
    echo ""
}

# Run script
main "$@"
