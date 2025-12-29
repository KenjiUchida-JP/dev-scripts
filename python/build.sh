#!/usr/bin/env bash
# ==================================================
# Build Script
# Embeds .gitignore.template into setup-project.sh
# ==================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_FILE="${SCRIPT_DIR}/.gitignore.template"
TARGET_FILE="${SCRIPT_DIR}/setup-project.sh"

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# --------------------------------------------------
# Check if template file exists
# --------------------------------------------------
if [[ ! -f "$TEMPLATE_FILE" ]]; then
    echo -e "${RED}Error:${NC} $TEMPLATE_FILE not found" >&2
    exit 1
fi

if [[ ! -f "$TARGET_FILE" ]]; then
    echo -e "${RED}Error:${NC} $TARGET_FILE not found" >&2
    exit 1
fi

# --------------------------------------------------
# Read template content
# --------------------------------------------------
TEMPLATE_CONTENT=$(cat "$TEMPLATE_FILE")

# --------------------------------------------------
# Generate new generate_gitignore function
# --------------------------------------------------
NEW_FUNCTION=$(cat << 'FUNC_START'
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
FUNC_START
)

NEW_FUNCTION="${NEW_FUNCTION}
${TEMPLATE_CONTENT}
GITIGNORE_EOF
    fi
}"

# --------------------------------------------------
# Update setup-project.sh
# Markers: # --- BEGIN GITIGNORE_FUNC --- and # --- END GITIGNORE_FUNC ---
# --------------------------------------------------

# Check if markers exist
if ! grep -q "# --- BEGIN GITIGNORE_FUNC ---" "$TARGET_FILE"; then
    echo -e "${RED}Error:${NC} Markers not found. Please add markers to setup-project.sh" >&2
    exit 1
fi

# Create temporary file
TEMP_FILE=$(mktemp)

# Replace between markers
awk -v new_func="$NEW_FUNCTION" '
    /# --- BEGIN GITIGNORE_FUNC ---/ {
        print "# --- BEGIN GITIGNORE_FUNC ---"
        print new_func
        skip = 1
        next
    }
    /# --- END GITIGNORE_FUNC ---/ {
        print "# --- END GITIGNORE_FUNC ---"
        skip = 0
        next
    }
    !skip { print }
' "$TARGET_FILE" > "$TEMP_FILE"

# --------------------------------------------------
# Check diff and update
# --------------------------------------------------
if diff -q "$TARGET_FILE" "$TEMP_FILE" > /dev/null 2>&1; then
    echo -e "${YELLOW}No changes:${NC} $TARGET_FILE is up to date"
    rm "$TEMP_FILE"
else
    mv "$TEMP_FILE" "$TARGET_FILE"
    chmod +x "$TARGET_FILE"
    echo -e "${GREEN}Updated:${NC} $TARGET_FILE has been updated"
fi
