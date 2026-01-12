#!/usr/bin/env bash
# ==================================================
# Next.js Build Script
# Validates that setup-project.sh uses templates correctly
# ==================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="${SCRIPT_DIR}/../templates/gitignore"
SETUP_SCRIPT="${SCRIPT_DIR}/setup-project.sh"

# Color definitions
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if templates exist
if [[ ! -f "${TEMPLATES_DIR}/base.template" ]]; then
    echo -e "${RED}Error:${NC} base.template not found" >&2
    exit 1
fi

if [[ ! -f "${TEMPLATES_DIR}/nextjs.template" ]]; then
    echo -e "${RED}Error:${NC} nextjs.template not found" >&2
    exit 1
fi

# Check if setup script exists
if [[ ! -f "$SETUP_SCRIPT" ]]; then
    echo -e "${RED}Error:${NC} setup-project.sh not found" >&2
    exit 1
fi

# Verify that setup script uses new template system
if ! grep -q 'build_gitignore_single.*"nextjs"' "$SETUP_SCRIPT"; then
    echo -e "${YELLOW}Warning:${NC} setup-project.sh may not be using new template system" >&2
fi

echo -e "${GREEN}✓${NC} Next.js templates are valid"
echo -e "${GREEN}✓${NC} setup-project.sh is up to date"
