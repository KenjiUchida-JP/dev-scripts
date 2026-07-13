# dev-scripts

🇺🇸 English | [🇯🇵 日本語](./README.ja.md)

Scripts that set up an isolated, per-project Python or Node.js runtime environment in the current directory — so tools like Claude Code can run scripts in a local sandbox instead of the global environment.

These scripts do **not** scaffold an application. There's no framework, no starter UI, no `.env` samples for a database or auth provider — just a working interpreter, a package manager, and a `src/` folder to write code in.

All scripts run **in the current directory** — `cd` into the target project folder first, then invoke the setup script.

## 1. Quick Start

### Python Environment

Run the setup in your project directory:

```bash
mkdir my-project && cd my-project
bash <(curl -fsSL https://raw.githubusercontent.com/KenjiUchida-JP/dev-scripts/main/python/setup-project.sh)
```

**Prerequisites:** [uv](https://docs.astral.sh/uv/)

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### Node.js Environment

```bash
mkdir my-scripts && cd my-scripts
bash <(curl -fsSL https://raw.githubusercontent.com/KenjiUchida-JP/dev-scripts/main/nodejs/setup-project.sh)
```

**Prerequisites:** [Node.js](https://nodejs.org/) (via [nvm](https://github.com/nvm-sh/nvm) or [fnm](https://github.com/Schniz/fnm) recommended)

### Full-stack (Python + Node.js) Environment

Use this when you want **both** environments in the same repository. Running `python/setup-project.sh` and `nodejs/setup-project.sh` back-to-back in the same directory does *not* merge their `.gitignore` / `CLAUDE.md.temp` / `.vscode/settings.json` — whichever runs first "wins" and the second run silently skips regenerating those files, since both scripts preserve existing files by design. `fullstack/setup-project.sh` runs both installs in one pass and generates a merged `.gitignore`, `.vscode/settings.json`, and `CLAUDE.md.temp` that cover both languages.

If you don't have a project directory yet:

```bash
mkdir my-fullstack-project && cd my-fullstack-project
```

Run the setup in your project directory:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/KenjiUchida-JP/dev-scripts/main/fullstack/setup-project.sh)
```

**Prerequisites:** both [uv](https://docs.astral.sh/uv/) and [Node.js](https://nodejs.org/) (see above)

## 2. Behavior

### Execution model

- The script always operates on the **current working directory**.
- The project name is auto-derived from the directory name — there is no project-name prompt.
- The script aborts immediately when fatal collisions are detected (e.g. existing `.venv/`, `pyproject.toml`, `node_modules/`, `package.json`).
- Files that the script normally generates are **preserved when they already exist**:
  - `README.md`
  - `.gitignore`
  - `.vscode/settings.json`
  - `CLAUDE.md.temp`
  - `.git/` (skips `git init`)
- When Git is initialized, the default branch is always `main` (`git init -b main`), regardless of the local machine's `init.defaultBranch` setting.

### Python Environment

- Interactive setup for Python version and project type (app/lib)
- Virtual environment (`.venv/`) managed by [uv](https://docs.astral.sh/uv/)
- `pyproject.toml` with tool configurations
- `.gitignore` with sensible defaults (skipped if existing)
- `src/` directory with `__init__.py`
- `tests/` directory with `conftest.py` (when dev tools selected)
- Optional dev tools: ruff, mypy, pytest
- `.vscode/settings.json` with the Python interpreter path (skipped if existing)
- `CLAUDE.md.temp` with project conventions for Claude Code (skipped if existing)
- Initialized Git repository (skipped if `.git/` exists)

Run scripts with `uv run python src/...` — no manual `source .venv/bin/activate` needed.

### Node.js Environment

- Interactive setup for Node.js version and package manager (npm/pnpm/yarn/bun) — **pnpm is the default when it's installed**
- `package.json` and local `node_modules/` in the current directory
- TypeScript + [tsx](https://github.com/privatenumber/tsx) so `.ts` files run directly, no build step required
- `src/index.ts` entry stub
- Optional dev tools: eslint, prettier, vitest
- `.gitignore` with sensible defaults (skipped if existing)
- `.vscode/settings.json` (skipped if existing)
- `CLAUDE.md.temp` with project conventions for Claude Code (skipped if existing)
- `.nvmrc` / `.node-version` (when a version manager is detected)
- When pnpm or yarn is selected, `packageManager` is pinned in `package.json` (`pnpm@<version>`) so [corepack](https://nodejs.org/api/corepack.html) enforces the same package manager for anyone working on the project

Run scripts with `pnpm run start` (or the equivalent for your package manager).

### Full-stack (Python + Node.js) Environment

- Runs the Python setup and the Node.js setup in a single pass, sharing one `src/` directory (`src/__init__.py` and `src/index.ts` coexist)
- `.gitignore` is the **merged** Python + Node.js template (base + python + nodejs, with duplicate patterns like `tmp/` deduped) — skipped if a `.gitignore` already exists
- `.vscode/settings.json` is the **merged** template (Python interpreter path + ESLint/Prettier formatter settings) — skipped if already existing
- `CLAUDE.md.temp` documents **both** the Python and Node.js conventions in one file — skipped if already existing
- Same fatal-collision checks as the individual scripts apply for both languages (aborts if `.venv/`, `pyproject.toml`, `node_modules/`, `package.json`, etc. already exist)

## 3. Notes / Gotchas

### fnm has no self-update command

`fnm` doesn't ship a `fnm update` or self-update subcommand. To upgrade it, re-run the official installer — it overwrites the existing binary in place, no shell config changes needed:

```bash
curl -fsSL https://fnm.vercel.app/install | bash
```

### Enable corepack for the `packageManager` pin to actually take effect

When pnpm or yarn is selected, the setup script pins it in `package.json` via `"packageManager": "pnpm@<version>"`. This pin is only *enforced* if [corepack](https://nodejs.org/api/corepack.html) is enabled:

```bash
corepack enable
```

Node.js ships with corepack already installed, but it isn't enabled by default. Without running this once, `packageManager` is just metadata — whatever pnpm/yarn binary happens to be first on your `PATH` still wins. Each Node.js version installed via fnm/nvm gets its own shim directory, so re-run `corepack enable` after installing a new Node.js version.

### pnpm and blocked build scripts

Recent pnpm versions (v10+) block dependency lifecycle scripts (e.g. `esbuild`'s postinstall) by default for supply-chain safety, and `pnpm add`/`pnpm install` exit non-zero when scripts get skipped as a result — even though the packages themselves installed successfully. The setup script handles this automatically (it runs `pnpm approve-builds --all` when needed), so an `[ERR_PNPM_IGNORED_BUILDS]` notice during setup is expected and already handled — no action needed.

### Mixing package managers on one machine is fine; mixing them in one project is not

It's normal to have both npm and pnpm (or others) installed on the same machine — npm ships with Node.js itself, and having a second package manager installed alongside it doesn't cause conflicts. What actually breaks things is running a *different* package manager inside the same project than the one its lockfile was generated with (e.g. `npm install` in a project with `pnpm-lock.yaml`). Stick to one package manager per project — the `packageManager` field above helps enforce that once corepack is enabled.

## 4. License

MIT License
