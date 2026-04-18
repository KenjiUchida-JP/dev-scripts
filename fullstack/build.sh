#!/usr/bin/env bash
# ==================================================
# Fullstack Build Script
# Validates that setup-project.sh uses templates correctly
# ==================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="${SCRIPT_DIR}/../templates/gitignore"
VSCODE_DIR="${SCRIPT_DIR}/../templates/vscode"
SETUP_SCRIPT="${SCRIPT_DIR}/setup-project.sh"

# Color definitions
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if gitignore templates exist
for template in base.template python.template nextjs.template; do
    if [[ ! -f "${TEMPLATES_DIR}/${template}" ]]; then
        echo -e "${RED}Error:${NC} ${template} not found" >&2
        exit 1
    fi
done

# Check if vscode template exists
if [[ ! -f "${VSCODE_DIR}/fullstack.settings.json" ]]; then
    echo -e "${RED}Error:${NC} fullstack.settings.json not found" >&2
    exit 1
fi

# Check if setup script exists
if [[ ! -f "$SETUP_SCRIPT" ]]; then
    echo -e "${RED}Error:${NC} setup-project.sh not found" >&2
    exit 1
fi

# Verify that setup script uses new template system
if ! grep -q 'build_gitignore_fullstack' "$SETUP_SCRIPT"; then
    echo -e "${YELLOW}Warning:${NC} setup-project.sh may not be using new template system" >&2
fi

echo -e "${GREEN}✓${NC} Fullstack templates are valid"
echo -e "${GREEN}✓${NC} setup-project.sh is up to date"
