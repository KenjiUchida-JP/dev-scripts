# dev-scripts

A collection of scripts for development environment setup and automation.

## 1. Quick Start

Create a new Python project instantly with a single command:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/KenjiUchida-JP/dev-scripts/main/python/setup-project.sh)
```

**Prerequisites:**
- [uv](https://docs.astral.sh/uv/) must be installed

  ```bash
  # Install uv (if not already installed)
  curl -LsSf https://astral.sh/uv/install.sh | sh
  ```

## 2. What It Does

The setup script will interactively guide you through:

- **Project name** - Enter your project name
- **Python version** - Select Python version (auto-detects latest available)
- **Project type** - Choose between `app` (application) or `lib` (library)
- **Development tools** - Optionally install ruff, mypy, and pytest

After completion, you'll have a fully configured Python project with:
- Virtual environment (`.venv/`)
- `pyproject.toml` with tool configurations
- `.gitignore` with sensible defaults
- `src/` directory with `__init__.py`
- `tests/` directory with `conftest.py` (if dev tools selected)
- `.vscode/settings.json` with Python interpreter path
- Initialized Git repository

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
├── python/
│   ├── setup-project.sh      # Python project setup
│   ├── build.sh              # Template sync build
│   └── .gitignore.template   # .gitignore template
├── hooks/
│   └── pre-commit            # Git pre-commit hook
├── scripts/
│   └── setup-hooks.sh        # Git hooks setup
└── .github/
    └── workflows/
        └── check-build.yml   # CI: Template sync check
```

### About Git Hooks

Scripts in the `hooks/` directory are set up as symbolic links to `.git/hooks/` by running `./scripts/setup-hooks.sh`.

**Current hooks:**
- `pre-commit`: Checks sync between `.gitignore.template` and `setup-project.sh` before commit

### Updating Templates

If you edit `.gitignore.template`, the heredoc in `setup-project.sh` will be automatically updated on commit. To update manually:

```bash
./python/build.sh
```

## 4. License

MIT License
