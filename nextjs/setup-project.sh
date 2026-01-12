#!/usr/bin/env bash
# ==================================================
# Next.js Project Setup Script
# Automatic Next.js environment setup with recommended settings
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
    curl -fsSL "$REPO_BASE/templates/gitignore/nextjs.template" -o "$TEMP_DIR/templates/gitignore/nextjs.template"

    mkdir -p "$TEMP_DIR/templates/vscode"
    curl -fsSL "$REPO_BASE/templates/vscode/nextjs.settings.json" -o "$TEMP_DIR/templates/vscode/nextjs.settings.json"

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
# Custom header for Next.js projects
# --------------------------------------------------
print_nextjs_header() {
    echo -e "\n${CYAN}⚡ Next.js Project Setup${NC}"
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

    # Prefer new template system
    if [[ -f "${templates_dir}/base.template" && -f "${templates_dir}/nextjs.template" ]]; then
        build_gitignore_single "$templates_dir" "nextjs"
    # Fallback to old location (backward compatibility)
    elif [[ -f "${SCRIPT_DIR}/.gitignore.template" ]]; then
        cat "${SCRIPT_DIR}/.gitignore.template"
    else
        # Last resort: heredoc for curl usage
        cat << 'GITIGNORE_EOF'
# ==================================================
# Next.js Project .gitignore Template
# ==================================================

# --------------------------------------------------
# Dependencies
# --------------------------------------------------
node_modules/
.pnp/
.pnp.js

# --------------------------------------------------
# Build / Production
# --------------------------------------------------
.next/
out/
build/
dist/

# --------------------------------------------------
# Testing
# --------------------------------------------------
coverage/
.nyc_output/

# --------------------------------------------------
# Environment Variables / Secrets
# --------------------------------------------------
.env
.env.local
.env.*.local
.env.development.local
.env.test.local
.env.production.local
*.pem

# --------------------------------------------------
# Debug / Logs
# --------------------------------------------------
npm-debug.log*
yarn-debug.log*
yarn-error.log*
.pnpm-debug.log*

# --------------------------------------------------
# Vercel
# --------------------------------------------------
.vercel

# --------------------------------------------------
# TypeScript
# --------------------------------------------------
*.tsbuildinfo
next-env.d.ts

# --------------------------------------------------
# IDE / Editor
# --------------------------------------------------
.idea/
.cursor/
.claude/
*.swp
*.swo
*~

# --------------------------------------------------
# OS Generated
# --------------------------------------------------
.DS_Store
Thumbs.db

# --------------------------------------------------
# Misc
# --------------------------------------------------
*.log
tmp/
GITIGNORE_EOF
    fi
}

# --------------------------------------------------
# Generate .env.example
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
# Generate VS Code settings
# --------------------------------------------------
generate_vscode_settings() {
    local vscode_template="${SCRIPT_DIR}/templates/vscode/nextjs.settings.json"
    if [[ -f "$vscode_template" ]]; then
        cat "$vscode_template"
    else
        # Fallback to inline template
        cat << 'VSCODE_EOF'
{
    "editor.formatOnSave": true,
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.codeActionsOnSave": {
        "source.fixAll.eslint": "explicit"
    },
    "[typescript]": {
        "editor.defaultFormatter": "esbenp.prettier-vscode"
    },
    "[typescriptreact]": {
        "editor.defaultFormatter": "esbenp.prettier-vscode"
    },
    "[javascript]": {
        "editor.defaultFormatter": "esbenp.prettier-vscode"
    },
    "[javascriptreact]": {
        "editor.defaultFormatter": "esbenp.prettier-vscode"
    },
    "[json]": {
        "editor.defaultFormatter": "esbenp.prettier-vscode"
    },
    "typescript.tsdk": "node_modules/typescript/lib"
}
VSCODE_EOF
    fi
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
# Main process
# --------------------------------------------------
main() {
    print_nextjs_header

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
    # 3. Project name input
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
    # 4. Setup mode selection (new or existing directory)
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
    # 5. Package manager selection
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
    # 6. Install Prettier
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
    echo "  Node.js version: $SELECTED_NODE_VERSION"
    echo "  Setup mode: $SETUP_MODE"
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

    # Determine package manager flag for create-next-app
    case "$PKG_MANAGER" in
        npm)
            PKG_FLAG=""
            ;;
        pnpm)
            PKG_FLAG="--use-pnpm"
            ;;
        yarn)
            PKG_FLAG="--use-yarn"
            ;;
        bun)
            PKG_FLAG="--use-bun"
            ;;
    esac

    # 1. Create Next.js project
    print_step "Creating Next.js project with recommended settings..."

    if [[ "$SETUP_MODE" == "existing" ]]; then
        cd "$PROJECT_NAME"
        npx create-next-app@latest . \
            --typescript \
            --eslint \
            --tailwind \
            --src-dir \
            --app \
            --import-alias "@/*" \
            $PKG_FLAG
        cd ..
    else
        npx create-next-app@latest "$PROJECT_NAME" \
            --typescript \
            --eslint \
            --tailwind \
            --src-dir \
            --app \
            --import-alias "@/*" \
            $PKG_FLAG
    fi

    print_success "Created Next.js project"

    cd "$PROJECT_NAME"

    # 2. Install Prettier
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

    # 3. Generate .gitignore (replace default)
    print_step "Generating .gitignore..."
    generate_gitignore > .gitignore
    print_success "Generated .gitignore"

    # 4. Generate .env.example
    print_step "Generating .env.example..."
    generate_env_example > .env.example
    print_success "Generated .env.example"

    # 5. Generate VS Code settings
    print_step "Generating .vscode/settings.json..."
    mkdir -p .vscode
    generate_vscode_settings > .vscode/settings.json
    print_success "Generated .vscode/settings.json"

    # 6. Generate .nvmrc / .node-version (if version manager was used)
    if [[ "$VERSION_MANAGER" != "none" ]]; then
        print_step "Generating .nvmrc and .node-version..."
        # .nvmrc for nvm compatibility
        echo "$SELECTED_NODE_VERSION" > .nvmrc
        # .node-version for fnm and other tools
        echo "$SELECTED_NODE_VERSION" > .node-version
        print_success "Generated .nvmrc and .node-version"
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
    echo "  cd $PROJECT_NAME"
    if [[ "$VERSION_MANAGER" == "fnm" ]]; then
        echo "  fnm use                # Use project's Node version"
    elif [[ "$VERSION_MANAGER" == "nvm" ]]; then
        echo "  nvm use                # Use project's Node version"
    fi
    echo "  $PKG_MANAGER run dev"
    echo ""
    echo "Useful commands:"
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
    echo "Open in browser: http://localhost:3000"
    echo ""
}

# Run script
main "$@"
