# Templates

This directory contains centralized templates used by all setup scripts.

## Directory Structure

```
templates/
├── gitignore/                      # Modular .gitignore templates
│   ├── base.template               # Common patterns (IDE, OS, env vars)
│   ├── python.template             # Python-specific patterns
│   └── nextjs.template             # Next.js-specific patterns
└── vscode/                         # VS Code settings templates
    ├── python.settings.json        # Python development settings
    ├── nextjs.settings.json        # Next.js development settings
    └── fullstack.settings.json     # Merged settings for fullstack projects
```

## Usage

### .gitignore Templates

Templates are composed using `scripts/lib/gitignore-builder.sh`:

```bash
# Single language
build_gitignore "base" "python"  # Python project
build_gitignore "base" "nextjs"  # Next.js project

# Fullstack with path prefixes
build_gitignore_with_prefixes \
    "base:." \
    "python:backend" \
    "nextjs:frontend"
```

**Template Composition Rules:**
1. `base.template` is always included first
2. Language-specific templates are appended
3. Blank lines between sections for readability
4. Comments preserved from source templates

### VS Code Settings Templates

Settings are merged using `jq` for fullstack projects:

```bash
# Single language
cp templates/vscode/python.settings.json .vscode/settings.json

# Fullstack (merged)
cp templates/vscode/fullstack.settings.json .vscode/settings.json
```

## Maintenance

### Adding New Templates

1. Create template file in appropriate subdirectory
2. Update `scripts/lib/gitignore-builder.sh` if needed
3. Add build script in language directory
4. Update setup script to use new template

### Modifying Templates

When templates are modified, setup scripts must be regenerated:

```bash
# Manual update
./python/build.sh
./nextjs/build.sh

# Automatic on commit
# pre-commit hook runs all build scripts
git commit -m "Update templates"
```

### Template Validation

Templates are validated in CI:

- `.github/workflows/check-build.yml` runs all build scripts
- Checks for uncommitted changes after build
- Ensures templates and setup scripts stay in sync

## Design Principles

1. **Single Source of Truth**: All templates in one place
2. **Composability**: Mix and match templates for different project types
3. **DRY**: Common patterns defined once in `base.template`
4. **Automation**: Build scripts keep everything in sync
5. **Backward Compatibility**: Old template locations deprecated but still work
