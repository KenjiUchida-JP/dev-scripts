# dev-scripts

🇺🇸 English | [🇯🇵 日本語](./README.ja.md)

A collection of scripts for development environment setup and automation.

## 1. Quick Start

### Python Project

Create a new Python project instantly:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/KenjiUchida-JP/dev-scripts/main/python/setup-project.sh)
```

**Prerequisites:** [uv](https://docs.astral.sh/uv/)

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### Next.js Project

Create a new Next.js project:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/KenjiUchida-JP/dev-scripts/main/nextjs/setup-project.sh)
```

**Prerequisites:** [Node.js](https://nodejs.org/) (via [nvm](https://github.com/nvm-sh/nvm) or [fnm](https://github.com/Schniz/fnm) recommended)

### Fullstack Project (Python + Next.js)

Create a fullstack project with both backend and frontend:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/KenjiUchida-JP/dev-scripts/main/fullstack/setup-project.sh)
```

**Prerequisites:** Both `uv` and Node.js

## 2. What It Does

### Python Project

- Interactive setup for project name, Python version, and type (app/lib)
- Virtual environment (`.venv/`)
- `pyproject.toml` with tool configurations
- `.gitignore` with sensible defaults
- `src/` directory with `__init__.py`
- `tests/` directory with `conftest.py` (if dev tools selected)
- `.vscode/settings.json` with Python interpreter path
- Initialized Git repository

### Next.js Project

- Interactive setup for project name and Node.js version
- Next.js project with TypeScript and `src/` directory
- `.gitignore` with sensible defaults
- `.vscode/settings.json` with Prettier and ESLint settings
- Node version files (`.nvmrc`, `.node-version`)
- Initialized Git repository

### Fullstack Project

- Monorepo structure with `frontend/` and `backend/` directories
- Combined `.gitignore` with path prefixes
- Merged `.vscode/settings.json` for both languages
- Both Python and Node.js development environments
- Frontend with `src/` directory structure
- No pre-configured `.env` files (create as needed for your project)

## 3. For Contributors

If you want to contribute to this repository, clone it and set up Git hooks:

```bash
git clone https://github.com/KenjiUchida-JP/dev-scripts.git
cd dev-scripts
./scripts/setup-hooks.sh
```

### Directory Structure

```
dev-scripts/
├── templates/                # Centralized template storage
│   ├── gitignore/           # Modular .gitignore templates
│   │   ├── base.template    # Common (IDE, OS, env vars)
│   │   ├── python.template  # Python-specific
│   │   └── nextjs.template  # Next.js-specific
│   └── vscode/              # VS Code settings templates
│       ├── python.settings.json
│       ├── nextjs.settings.json
│       └── fullstack.settings.json
├── python/
│   ├── setup-project.sh     # Python project setup
│   └── build.sh             # Template sync build
├── nextjs/
│   ├── setup-project.sh     # Next.js project setup
│   └── build.sh             # Template sync build
├── fullstack/
│   └── setup-project.sh     # Fullstack project setup
├── scripts/
│   ├── setup-hooks.sh       # Git hooks installer
│   └── lib/                 # Shared library functions
│       ├── colors.sh        # Color output helpers
│       ├── validators.sh    # Input validation
│       └── gitignore-builder.sh  # Template composition
├── hooks/
│   └── pre-commit           # Git pre-commit hook
└── .github/
    └── workflows/
        └── check-build.yml  # CI: Template sync check
```

### About Git Hooks

Scripts in the `hooks/` directory are set up as symbolic links to `.git/hooks/` by running `./scripts/setup-hooks.sh`.

**Current hooks:**
- `pre-commit`: Syncs all templates before commit

### Updating Templates

If you edit templates in `templates/`, the setup scripts will be automatically updated on commit. To update manually:

```bash
./python/build.sh
./nextjs/build.sh
```

## 4. License

MIT License
