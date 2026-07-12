#!/usr/bin/env bash
# ==================================================
# Node.js Project Setup Script
# Sets up a local Node.js + TypeScript runtime environment
# (no application framework — for running scripts, not building apps)
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
    curl -fsSL "$REPO_BASE/templates/gitignore/nodejs.template" -o "$TEMP_DIR/templates/gitignore/nodejs.template"

    mkdir -p "$TEMP_DIR/templates/vscode"
    curl -fsSL "$REPO_BASE/templates/vscode/nodejs.settings.json" -o "$TEMP_DIR/templates/vscode/nodejs.settings.json"

    mkdir -p "$TEMP_DIR/templates/claude"
    curl -fsSL "$REPO_BASE/templates/claude/nodejs.template.md" -o "$TEMP_DIR/templates/claude/nodejs.template.md"

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

# --------------------------------------------------
# Custom header for Node.js projects
# --------------------------------------------------
print_nodejs_header() {
    echo -e "\n${CYAN}⬢ Node.js Project Setup${NC}"
    echo "=================================================="
}

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

# --------------------------------------------------
# fnm (Fast Node Manager) functions
# --------------------------------------------------

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
# .gitignore generation function
# --------------------------------------------------
generate_gitignore() {
    local templates_dir="${SCRIPT_DIR}/templates/gitignore"
    build_gitignore_single "$templates_dir" "nodejs"
}

# --------------------------------------------------
# Generate VS Code settings
# --------------------------------------------------
generate_vscode_settings() {
    cat "${SCRIPT_DIR}/templates/vscode/nodejs.settings.json"
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
    print_nodejs_header

    # --------------------------------------------------
    # 0. Fatal collision check (current directory)
    # --------------------------------------------------
    if ! check_node_collisions; then
        print_error "Existing Node.js project files detected. Aborting to protect them."
        exit 1
    fi

    # --------------------------------------------------
    # 1. Check prerequisites and version managers
    # --------------------------------------------------
    print_step "Checking prerequisites..."

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
    # 2. Node.js version selection (if version manager available)
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
    # 3. Package manager selection (pnpm preferred by default)
    # --------------------------------------------------
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

    # --------------------------------------------------
    # 4. Development tools confirmation
    # --------------------------------------------------
    echo -ne "${CYAN}🛠️  Install development tools (eslint, prettier, vitest) [Y/n]: ${NC}"
    read -r INSTALL_DEV_TOOLS
    INSTALL_DEV_TOOLS="${INSTALL_DEV_TOOLS:-Y}"

    # --------------------------------------------------
    # Configuration summary
    # --------------------------------------------------
    echo ""
    echo "=================================================="
    echo -e "${YELLOW}Configuration:${NC}"
    echo "  Working directory: $(pwd)"
    echo "  Node.js version: $SELECTED_NODE_VERSION"
    echo "  Package manager: $PKG_MANAGER"
    echo "  TypeScript: Yes (tsx for direct script execution)"
    echo "  Development tools: $([[ "$INSTALL_DEV_TOOLS" =~ ^[Yy]$ ]] && echo "Install (eslint, prettier, vitest)" || echo "Skip")"
    echo "=================================================="
    echo ""

    # --------------------------------------------------
    # Detect existing files we should preserve
    # --------------------------------------------------
    local has_existing_gitignore=0
    local has_existing_vscode=0
    local has_existing_git=0
    local has_existing_claude_md=0
    [[ -f ".gitignore" ]] && has_existing_gitignore=1
    [[ -f ".vscode/settings.json" ]] && has_existing_vscode=1
    [[ -d ".git" ]] && has_existing_git=1
    [[ -f "CLAUDE.md.temp" ]] && has_existing_claude_md=1

    # --------------------------------------------------
    # Start setup
    # --------------------------------------------------
    echo -e "${GREEN}✨ Starting setup...${NC}\n"

    # 1. Initialize package.json (name auto-derived from current dir by npm)
    print_step "Initializing package.json..."
    npm init -y >/dev/null
    print_success "Initialized package.json"

    # pnpm ignores dependency build scripts by default (supply-chain safety).
    # esbuild (pulled in by tsx/vitest) relies on its postinstall to fetch its
    # native binary, so pre-approve it before any install runs the script.
    if [[ "$PKG_MANAGER" == "pnpm" ]]; then
        node -e "
            const fs = require('fs');
            const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
            pkg.pnpm = pkg.pnpm || {};
            pkg.pnpm.onlyBuiltDependencies = pkg.pnpm.onlyBuiltDependencies || [];
            if (!pkg.pnpm.onlyBuiltDependencies.includes('esbuild')) {
                pkg.pnpm.onlyBuiltDependencies.push('esbuild');
            }
            fs.writeFileSync('package.json', JSON.stringify(pkg, null, 4) + '\n');
        "
    fi

    # 2. Install TypeScript + tsx (run .ts files directly, no build step needed)
    print_step "Installing TypeScript runtime (typescript, tsx, @types/node)..."
    case "$PKG_MANAGER" in
        npm)  npm install --save-dev "typescript@^5" tsx @types/node ;;
        pnpm) pnpm add -D "typescript@^5" tsx @types/node ;;
        yarn) yarn add -D "typescript@^5" tsx @types/node ;;
        bun)  bun add -D "typescript@^5" tsx @types/node ;;
    esac
    print_success "Installed TypeScript runtime"

    # 3. Generate tsconfig.json
    print_step "Generating tsconfig.json..."
    generate_tsconfig > tsconfig.json
    print_success "Generated tsconfig.json"

    # 4. Create src directory with entry stub
    print_step "Creating src directory..."
    mkdir -p src
    [[ ! -f "src/index.ts" ]] && generate_index_ts > src/index.ts
    print_success "Created src directory"

    # 5. Install development tools
    if [[ "$INSTALL_DEV_TOOLS" =~ ^[Yy]$ ]]; then
        print_step "Installing development tools..."
        case "$PKG_MANAGER" in
            npm)  npm install --save-dev eslint @eslint/js typescript-eslint prettier eslint-config-prettier vitest ;;
            pnpm) pnpm add -D eslint @eslint/js typescript-eslint prettier eslint-config-prettier vitest ;;
            yarn) yarn add -D eslint @eslint/js typescript-eslint prettier eslint-config-prettier vitest ;;
            bun)  bun add -D eslint @eslint/js typescript-eslint prettier eslint-config-prettier vitest ;;
        esac
        print_success "Installed development tools"

        print_step "Generating eslint.config.mjs..."
        generate_eslint_config > eslint.config.mjs
        print_success "Generated eslint.config.mjs"

        print_step "Generating .prettierrc..."
        generate_prettier_config > .prettierrc
        print_success "Generated .prettierrc"
    fi

    # 6. Add npm scripts to package.json
    print_step "Updating package.json..."
    node -e "
        const fs = require('fs');
        const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
        pkg.scripts = pkg.scripts || {};
        pkg.scripts.start = 'tsx src/index.ts';
        pkg.scripts.build = 'tsc';
        pkg.scripts.typecheck = 'tsc --noEmit';
        $( [[ "$INSTALL_DEV_TOOLS" =~ ^[Yy]$ ]] && echo "
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

    # 7. Generate .gitignore (only when there is no existing one)
    if [[ $has_existing_gitignore -eq 0 ]]; then
        print_step "Generating .gitignore..."
        generate_gitignore > .gitignore
        print_success "Generated .gitignore"
    fi

    # 8. Generate .vscode/settings.json (skip if existing)
    if [[ $has_existing_vscode -eq 1 ]]; then
        print_warning "Existing .vscode/settings.json preserved (skipped)"
    else
        print_step "Generating .vscode/settings.json..."
        mkdir -p .vscode
        generate_vscode_settings > .vscode/settings.json
        print_success "Generated .vscode/settings.json"
    fi

    # 9. Generate .nvmrc / .node-version (if version manager was used)
    if [[ "$VERSION_MANAGER" != "none" ]]; then
        print_step "Generating .nvmrc and .node-version..."
        echo "$SELECTED_NODE_VERSION" > .nvmrc
        echo "$SELECTED_NODE_VERSION" > .node-version
        print_success "Generated .nvmrc and .node-version"
    fi

    # 10. Create CLAUDE.md.temp (skip if existing)
    if [[ $has_existing_claude_md -eq 1 ]]; then
        print_warning "Existing CLAUDE.md.temp preserved (skipped)"
    else
        print_step "Creating CLAUDE.md.temp..."
        cp "${SCRIPT_DIR}/templates/claude/nodejs.template.md" CLAUDE.md.temp
        print_success "Created CLAUDE.md.temp"
    fi

    # 11. Initialize Git (skip if existing)
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
    if [[ "$VERSION_MANAGER" == "fnm" ]]; then
        echo "  fnm use                # Use project's Node version"
    elif [[ "$VERSION_MANAGER" == "nvm" ]]; then
        echo "  nvm use                # Use project's Node version"
    fi
    echo "  $PKG_MANAGER run start"
    echo ""
    echo "Useful commands:"
    echo "  $PKG_MANAGER run start       # Run src/index.ts directly (tsx)"
    echo "  $PKG_MANAGER run typecheck   # Type-check without emitting"
    echo "  $PKG_MANAGER run build       # Compile to dist/"
    if [[ "$INSTALL_DEV_TOOLS" =~ ^[Yy]$ ]]; then
        echo "  $PKG_MANAGER run lint        # Run ESLint"
        echo "  $PKG_MANAGER run format      # Run Prettier"
        echo "  $PKG_MANAGER run test        # Run tests (vitest)"
    fi
    echo ""
}

# Run script
main "$@"
