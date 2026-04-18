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
build_gitignore_single "$templates_dir" "python"  # Python project
build_gitignore_single "$templates_dir" "nextjs"  # Next.js project

# Fullstack with path prefixes (python → backend/, nextjs → frontend/)
build_gitignore_fullstack "$templates_dir" "python" "nextjs"
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
3. Update the relevant setup script(s) to use the new template

### Modifying Templates

Setup scripts read these templates directly at runtime, so edits take effect immediately on the next setup run — no regeneration step required. Curl-based remote execution downloads the templates into a temp dir before running.

## Design Principles

1. **Single Source of Truth**: All templates in one place
2. **Composability**: Mix and match templates for different project types
3. **DRY**: Common patterns defined once in `base.template`
