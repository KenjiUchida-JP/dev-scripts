# Shared Library Functions

This directory contains reusable bash functions used across all setup scripts.

## Files

### colors.sh

Color output helpers for consistent terminal styling.

**Exports:**
```bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'  # No Color
```

**Functions:**
```bash
print_header "Title"       # Cyan header with separator
print_step "Step name"     # Blue step indicator
print_success "Message"    # Green success message
print_error "Message"      # Red error message (stderr)
print_warning "Message"    # Yellow warning message
```

**Usage:**
```bash
source "${SCRIPT_DIR}/../scripts/lib/colors.sh"

print_header "Project Setup"
print_step "Creating directory..."
print_success "Directory created"
print_warning "Node.js version is old"
print_error "Setup failed"
```

### validators.sh

Input validation and environment collision detection helpers.

**Functions:**
```bash
validate_project_name "project-name"   # Returns 0 if valid, 1 if invalid
validate_python_version "3.12.0"       # Returns 0 if valid, 1 if invalid

check_python_collisions                # Returns 0 if clean, 1 if Python project files exist
check_node_collisions                  # Returns 0 if clean, 1 if Node.js project files exist
check_fullstack_collisions             # Returns 0 if backend/ and frontend/ are empty/absent
```

**Validation Rules:**

Project name:
- Must not be empty
- Must start with a letter
- Can contain only: letters, numbers, hyphens, underscores
- Pattern: `^[a-zA-Z][a-zA-Z0-9_-]*$`

Python version:
- Format: `MAJOR.MINOR` or `MAJOR.MINOR.PATCH`
- Pattern: `^[0-9]+\.[0-9]+(\.[0-9]+)?$`
- Examples: `3.12`, `3.12.0`

**Collision detection:**

The `check_*_collisions` helpers print fatal items to stderr and return non-zero
when project files that would conflict with a fresh setup are present in the
current directory. They intentionally do *not* flag `README.md`, `.gitignore`,
or `.vscode/settings.json` — caller scripts handle those by skipping
regeneration so existing content is preserved.

**Usage:**
```bash
source "${SCRIPT_DIR}/../scripts/lib/validators.sh"

# Abort early if a previous Python environment exists in the current dir
if ! check_python_collisions; then
    print_error "Existing Python project files detected. Aborting."
    exit 1
fi

DEFAULT_PROJECT_NAME=$(basename "$(pwd)")
while true; do
    read -r PROJECT_NAME
    PROJECT_NAME="${PROJECT_NAME:-$DEFAULT_PROJECT_NAME}"
    if validate_project_name "$PROJECT_NAME"; then
        break
    else
        print_error "Invalid project name"
    fi
done
```

### gitignore-builder.sh

Template composition functions for building `.gitignore` files.

**Functions:**

#### get_templates_dir
```bash
get_templates_dir "$SCRIPT_DIR"
# Returns: "${SCRIPT_DIR}/../templates/gitignore"
```

Gets the path to the gitignore templates directory.

#### build_gitignore_single
```bash
build_gitignore_single "$TEMPLATES_DIR" "python"
build_gitignore_single "$TEMPLATES_DIR" "nextjs"
```

Builds `.gitignore` for single-language projects by concatenating:
1. `base.template` (common patterns)
2. Language-specific template

**Output format:**
```
# Base template content
.DS_Store
.env

# Language template content
__pycache__/
.venv/
```

#### build_gitignore_fullstack
```bash
build_gitignore_fullstack "$TEMPLATES_DIR" "python" "nextjs"
```

Builds `.gitignore` for fullstack projects with path prefixes:
- `python` patterns → `backend/` prefix
- `nextjs` patterns → `frontend/` prefix

**Output format:**
```
# Base template content (no prefix)
.DS_Store
.env

# --------------------------------------------------
# Backend (python)
# --------------------------------------------------
backend/__pycache__/
backend/.venv/

# --------------------------------------------------
# Frontend (nextjs)
# --------------------------------------------------
frontend/.next/
frontend/node_modules/
```

**Usage:**
```bash
source "${SCRIPT_DIR}/../scripts/lib/gitignore-builder.sh"

TEMPLATES_DIR=$(get_templates_dir "$SCRIPT_DIR")

# Single language
build_gitignore_single "$TEMPLATES_DIR" "python" > .gitignore

# Fullstack
build_gitignore_fullstack "$TEMPLATES_DIR" "python" "nextjs" > .gitignore
```

## Usage in Setup Scripts

### Import Libraries

Always import from script directory:

```bash
#!/usr/bin/env bash
set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Import libraries
source "${SCRIPT_DIR}/../scripts/lib/colors.sh"
source "${SCRIPT_DIR}/../scripts/lib/validators.sh"
source "${SCRIPT_DIR}/../scripts/lib/gitignore-builder.sh"
```

### Example: Python Setup Script

```bash
#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Import libraries
source "${SCRIPT_DIR}/../scripts/lib/colors.sh"
source "${SCRIPT_DIR}/../scripts/lib/validators.sh"
source "${SCRIPT_DIR}/../scripts/lib/gitignore-builder.sh"

main() {
    print_header "Python Project Setup"

    # Abort early on fatal collisions in the current directory
    if ! check_python_collisions; then
        print_error "Existing Python project files detected. Aborting."
        exit 1
    fi

    # Project name defaults to the current directory's basename
    DEFAULT_PROJECT_NAME=$(basename "$(pwd)")
    while true; do
        echo -ne "${CYAN}📦 Project name [${DEFAULT_PROJECT_NAME}]: ${NC}"
        read -r PROJECT_NAME
        PROJECT_NAME="${PROJECT_NAME:-$DEFAULT_PROJECT_NAME}"
        if validate_project_name "$PROJECT_NAME"; then
            break
        else
            print_error "Invalid project name"
        fi
    done

    # Generate .gitignore (skip if existing was preserved by the caller)
    if [[ ! -f ".gitignore" ]]; then
        print_step "Creating .gitignore..."
        TEMPLATES_DIR=$(get_templates_dir "$SCRIPT_DIR")
        build_gitignore_single "$TEMPLATES_DIR" "python" > .gitignore
        print_success ".gitignore created"
    fi
}

main "$@"
```

### Example: Fullstack Setup Script

```bash
#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/../scripts/lib/colors.sh"
source "${SCRIPT_DIR}/../scripts/lib/validators.sh"
source "${SCRIPT_DIR}/../scripts/lib/gitignore-builder.sh"

main() {
    print_header "Fullstack Project Setup"

    # ... project setup ...

    # Generate .gitignore with path prefixes
    print_step "Creating .gitignore..."
    TEMPLATES_DIR=$(get_templates_dir "$SCRIPT_DIR")
    build_gitignore_fullstack "$TEMPLATES_DIR" "python" "nextjs" > .gitignore
    print_success ".gitignore created"
}

main "$@"
```

## Adding New Functions

### 1. Choose the appropriate file

- **colors.sh**: Output formatting functions
- **validators.sh**: Input validation functions
- **gitignore-builder.sh**: Template composition functions

### 2. Follow naming conventions

- Use `snake_case` for function names
- Use descriptive names (`validate_email`, not `check`)
- Prefix internal functions with `_` (e.g., `_internal_helper`)

### 3. Document the function

Add comments describing:
- Purpose
- Parameters
- Return values
- Example usage

### 4. Test the function

Test in isolation before using in setup scripts:

```bash
source scripts/lib/validators.sh
validate_project_name "my-project" && echo "Valid" || echo "Invalid"
```

## Testing

### Manual Testing

```bash
# Test colors
source scripts/lib/colors.sh
print_success "Test successful"
print_error "Test failed"

# Test validators
source scripts/lib/validators.sh
validate_project_name "valid-project" && echo "Pass" || echo "Fail"
validate_project_name "123invalid" && echo "Pass" || echo "Fail"

# Test gitignore builder
source scripts/lib/gitignore-builder.sh
TEMPLATES_DIR="templates/gitignore"
build_gitignore_single "$TEMPLATES_DIR" "python"
```

### Integration Testing

Run setup scripts in a test directory:

```bash
cd /tmp
bash /path/to/dev-scripts/python/setup-project.sh
```

## Best Practices

1. **Keep functions small**: One function, one purpose
2. **Use meaningful names**: Function names should be self-documenting
3. **Validate inputs**: Check parameters before processing
4. **Handle errors**: Use `set -e` and check return codes
5. **Document thoroughly**: Add usage examples in comments
6. **Test in isolation**: Test each function independently
7. **Maintain backward compatibility**: Deprecate instead of removing

## Related Documentation

- [Main README](../../README.md) - Project overview
- [Templates](../../templates/README.md) - Template system
- [Python Setup](../../python/README.md) - Python setup script
- [Next.js Setup](../../nextjs/README.md) - Next.js setup script
- [Fullstack Setup](../../fullstack/README.md) - Fullstack setup script
