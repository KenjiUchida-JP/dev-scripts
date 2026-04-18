# dev-scripts

🇺🇸 English | [🇯🇵 日本語](./README.ja.md)

A collection of scripts for development environment setup and automation.

All scripts run **in the current directory** — `cd` into the target project folder first, then invoke the setup script.

## 1. Quick Start

### Python Project

Run the setup in your project directory:

```bash
mkdir my-project && cd my-project
bash <(curl -fsSL https://raw.githubusercontent.com/KenjiUchida-JP/dev-scripts/main/python/setup-project.sh)
```

**Prerequisites:** [uv](https://docs.astral.sh/uv/)

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### Next.js Project

```bash
mkdir my-app && cd my-app
bash <(curl -fsSL https://raw.githubusercontent.com/KenjiUchida-JP/dev-scripts/main/nextjs/setup-project.sh)
```

**Prerequisites:** [Node.js](https://nodejs.org/) (via [nvm](https://github.com/nvm-sh/nvm) or [fnm](https://github.com/Schniz/fnm) recommended)

### Fullstack Project (Python + Next.js)

```bash
mkdir my-fullstack && cd my-fullstack
bash <(curl -fsSL https://raw.githubusercontent.com/KenjiUchida-JP/dev-scripts/main/fullstack/setup-project.sh)
```

**Prerequisites:** Both `uv` and Node.js

## 2. Behavior

### Execution model

- The script always operates on the **current working directory**.
- The project name is auto-derived from the directory name by `uv init` and `create-next-app` — there is no project-name prompt.
- The script aborts immediately when fatal collisions are detected (e.g. existing `.venv/`, `pyproject.toml`, `node_modules/`, `package.json`).
- Files that the script normally generates are **preserved when they already exist**:
  - `README.md`
  - `.gitignore`
  - `.vscode/settings.json`
  - `.git/` (skips `git init`)

### Python Project

- Interactive setup for Python version and project type (app/lib)
- Virtual environment (`.venv/`)
- `pyproject.toml` with tool configurations
- `.gitignore` with sensible defaults (skipped if existing)
- `src/` directory with `__init__.py`
- `tests/` directory with `conftest.py` (when dev tools selected)
- `.vscode/settings.json` with Python interpreter path (skipped if existing)
- Initialized Git repository (skipped if `.git/` exists)

### Next.js Project

- Interactive setup for Node.js version, Next.js version, and package manager
- Next.js project with TypeScript and `src/` directory
- `.gitignore` replaced with project template (skipped if existing)
- `.vscode/settings.json` with Prettier and ESLint settings (skipped if existing)
- Node version files (`.nvmrc`, `.node-version`)

### Fullstack Project

- Monorepo structure with `backend/` and `frontend/` directories created in the current directory
- Combined `.gitignore` with path prefixes (skipped if existing)
- Merged `.vscode/settings.json` for both languages (skipped if existing)
- Interactive setup for Python version, Node.js version, and Next.js version
- Both Python and Node.js development environments
- Frontend with `src/` directory structure
- No pre-configured `.env` files (create as needed for your project)

## 3. License

MIT License
