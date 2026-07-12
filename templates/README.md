# Templates

This directory contains centralized templates used by all setup scripts.

## Directory Structure

```
templates/
├── gitignore/                      # Modular .gitignore templates
│   ├── base.template               # Common patterns (IDE, OS, env vars)
│   ├── python.template              # Python-specific patterns
│   └── nodejs.template             # Node.js-specific patterns
├── vscode/                         # VS Code settings templates
│   ├── python.settings.json        # Python development settings
│   └── nodejs.settings.json        # Node.js/TypeScript development settings
└── claude/                         # CLAUDE.md.temp templates (Claude Code guidance)
    ├── python.template.md          # Python project conventions
    └── nodejs.template.md          # Node.js project conventions
```

## Usage

### .gitignore Templates

Templates are composed using `scripts/lib/gitignore-builder.sh`:

```bash
build_gitignore_single "$templates_dir" "python"  # Python project
build_gitignore_single "$templates_dir" "nodejs"  # Node.js project
```

**Template Composition Rules:**
1. `base.template` is always included first
2. Language-specific templates are appended
3. Blank lines between sections for readability
4. Comments preserved from source templates

### VS Code Settings Templates

```bash
cp templates/vscode/python.settings.json .vscode/settings.json
# or
cp templates/vscode/nodejs.settings.json .vscode/settings.json
```

### CLAUDE.md.temp Templates

Copied as-is into the project root (skipped if `CLAUDE.md.temp` already exists), so Claude Code picks up the right conventions (how to run scripts, add packages, which lockfile to commit) for whichever environment was set up:

```bash
cp templates/claude/python.template.md CLAUDE.md.temp
# or
cp templates/claude/nodejs.template.md CLAUDE.md.temp
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
