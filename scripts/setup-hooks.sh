#!/usr/bin/env bash
# ==================================================
# Git Hooks Setup Script
# Creates symbolic links from hooks/ directory to .git/hooks/
# ==================================================

set -e

# Color definitions
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Get repository root directory
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOKS_DIR="${REPO_ROOT}/hooks"
GIT_HOOKS_DIR="${REPO_ROOT}/.git/hooks"

# Check if .git directory exists
if [[ ! -d "${REPO_ROOT}/.git" ]]; then
    echo -e "${RED}Error:${NC} .git directory not found"
    echo "Please run this script from the repository root"
    exit 1
fi

# Check if hooks directory exists
if [[ ! -d "$HOOKS_DIR" ]]; then
    echo -e "${RED}Error:${NC} hooks/ directory not found"
    exit 1
fi

echo -e "${GREEN}🔧 Setting up Git hooks...${NC}"

# Create symbolic links for each file in hooks/
for hook in "$HOOKS_DIR"/*; do
    if [[ -f "$hook" ]]; then
        hook_name=$(basename "$hook")
        target="${GIT_HOOKS_DIR}/${hook_name}"

        # Remove existing file/link if present
        if [[ -e "$target" || -L "$target" ]]; then
            rm "$target"
        fi

        # Create symbolic link
        ln -sf "../../hooks/${hook_name}" "$target"
        echo -e "  ${GREEN}✓${NC} ${hook_name}"
    fi
done

echo ""
echo -e "${GREEN}✅ Git hooks setup complete!${NC}"
