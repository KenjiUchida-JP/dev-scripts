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
│   ├── nodejs.settings.json        # Node.js/TypeScript development settings
│   └── fullstack.settings.json     # Merged Python + Node.js settings
└── claude/                         # CLAUDE.md.temp templates (Claude Code guidance)
    ├── python.template.md          # Python project conventions
    ├── nodejs.template.md          # Node.js project conventions
    └── fullstack.template.md       # Merged Python + Node.js project conventions
```

## Usage

### .gitignore Templates

Templates are composed using `scripts/lib/gitignore-builder.sh`:

```bash
build_gitignore_single "$templates_dir" "python"  # Python project
build_gitignore_single "$templates_dir" "nodejs"  # Node.js project
build_gitignore_combined "$templates_dir"         # Python + Node.js project
```

**Template Composition Rules:**
1. `base.template` is always included first
2. Language-specific templates are appended
3. Blank lines between sections for readability
4. Comments preserved from source templates
5. `build_gitignore_combined` additionally dedupes ignore patterns that appear in both `python.template` and `nodejs.template` (e.g. `tmp/`), while always keeping comments/blank lines so both templates' section headers stay intact

### VS Code Settings Templates

```bash
cp templates/vscode/python.settings.json .vscode/settings.json
# or
cp templates/vscode/nodejs.settings.json .vscode/settings.json
# or (Python + Node.js project)
cp templates/vscode/fullstack.settings.json .vscode/settings.json
```

`fullstack.settings.json` is maintained as a static, manually-merged file rather than being generated at runtime — it has no overlapping keys with either single-language template, so a plain union is safe and needs no JSON-merging dependency (e.g. `jq`).

### CLAUDE.md.temp Templates

Copied as-is into the project root (skipped if `CLAUDE.md.temp` already exists), so Claude Code picks up the right conventions (how to run scripts, add packages, which lockfile to commit) for whichever environment was set up:

```bash
cp templates/claude/python.template.md CLAUDE.md.temp
# or
cp templates/claude/nodejs.template.md CLAUDE.md.temp
# or (Python + Node.js project)
cp templates/claude/fullstack.template.md CLAUDE.md.temp
```

`fullstack.template.md` is likewise a static file merging both languages' sections under one `## 開発環境` header, rather than being stitched together programmatically.

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

## Related Documentation

- [Main README](../README.md) - Project overview, including the `fullstack/setup-project.sh` combined mode
- [Shared Library Functions](../scripts/lib/README.md) - `gitignore-builder.sh`, version-detection helpers, etc.
