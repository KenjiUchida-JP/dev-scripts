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

- Interactive setup for project name, Node.js version, and Next.js version
- Next.js project with TypeScript and `src/` directory
- `.gitignore` with sensible defaults
- `.vscode/settings.json` with Prettier and ESLint settings
- Node version files (`.nvmrc`, `.node-version`)
- Initialized Git repository

### Fullstack Project

- Monorepo structure with `frontend/` and `backend/` directories
- Combined `.gitignore` with path prefixes
- Merged `.vscode/settings.json` for both languages
- Interactive setup for Python version, Node.js version, and Next.js version
- Both Python and Node.js development environments
- Frontend with `src/` directory structure
- No pre-configured `.env` files (create as needed for your project)

## 3. License

MIT License
