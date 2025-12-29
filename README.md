# dev-scripts

A collection of scripts for development environment setup and automation.

## 1. Introduction

This repository contains scripts to automate the initial setup of development projects.

## 2. Setup

After cloning the repository, run the following command to set up Git hooks.

```bash
git clone https://github.com/YOUR_USERNAME/dev-scripts.git
cd dev-scripts
./scripts/setup-hooks.sh
```

## 3. Included Scripts

### 🐍 Python Project Setup

Automatically builds a Python project using `uv`.

```bash
./python/setup-project.sh
```

**Features:**
- Automatic Python environment setup
- Configuration of development tools (ruff, mypy, pytest)
- Automatic `.gitignore` generation
- Tool configuration appended to `pyproject.toml`

**Prerequisites:**
- [uv](https://docs.astral.sh/uv/) must be installed

## 4. Directory Structure

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

## 5. Developer Information

### About Git Hooks

Scripts in the `hooks/` directory are set up as symbolic links to `.git/hooks/` by running `./scripts/setup-hooks.sh`.

**Current hooks:**
- `pre-commit`: Checks sync between `.gitignore.template` and `setup-project.sh` before commit

### Updating Templates

If you edit `.gitignore.template`, the heredoc in `setup-project.sh` will be automatically updated on commit. To update manually, run the following command.

```bash
./python/build.sh
```

## 6. License

MIT License
