# Fullstack Project Setup

🇺🇸 English | [🇯🇵 日本語](./README.ja.md)

Automatic setup script for fullstack projects combining Python (backend) and Next.js (frontend).

## Features

- **Python Backend**
  - Managed with [uv](https://github.com/astral-sh/uv) (fast Python package manager)
  - Pre-configured with ruff, mypy, and pytest
  - Organized project structure with `src/` and `tests/`
  - VS Code integration with proper Python path

- **Next.js Frontend**
  - Latest Next.js with TypeScript and `src/` directory
  - Tailwind CSS for styling
  - ESLint for code quality
  - Prettier for consistent formatting
  - Automatic package manager detection (npm, pnpm, or yarn)
  - No pre-configured `.env` files (create as needed)

- **Unified Configuration**
  - Single `.gitignore` with path prefixes for both backend and frontend
  - Merged VS Code settings for seamless development
  - Root-level Git repository

## Prerequisites

### Required

- **Python & uv**: Install uv for Python package management
  ```bash
  curl -LsSf https://astral.sh/uv/install.sh | sh
  ```

- **Node.js**: Install Node.js (v18 or later recommended)
  - Using nvm: `nvm install --lts`
  - Using fnm: `fnm install --lts`
  - Direct download: https://nodejs.org/

### Optional

- **pnpm** or **yarn**: Alternative package managers (faster than npm)
  ```bash
  npm install -g pnpm
  # or
  npm install -g yarn
  ```

## Quick Start

### 1. Run the setup script

```bash
# From the fullstack directory
./setup-project.sh

# Or from the repository root
./fullstack/setup-project.sh
```

### 2. Enter project name

```
📦 Project name: my-awesome-app
```

### 3. Wait for setup to complete

The script will:
1. Create project directory structure
2. Generate unified `.gitignore`
3. Configure VS Code settings
4. Set up Python backend with uv
5. Set up Next.js frontend
6. Initialize Git repository

## Project Structure

After setup, your project will have this structure:

```
my-awesome-app/
├── .gitignore              # Unified gitignore for both backend and frontend
├── .vscode/
│   └── settings.json       # Merged VS Code settings
│
├── backend/                # Python project
│   ├── pyproject.toml      # Python dependencies and config
│   ├── .venv/              # Virtual environment
│   ├── src/
│   │   └── __init__.py
│   └── tests/
│       ├── __init__.py
│       └── conftest.py
│
└── frontend/               # Next.js project
    ├── package.json
    ├── tsconfig.json
    ├── .prettierrc
    ├── src/
    │   └── app/
    │       ├── page.tsx
    │       └── layout.tsx
    └── public/
```

## Development Workflow

### Backend (Python)

```bash
cd backend

# Add dependencies
uv add fastapi uvicorn

# Add development dependencies
uv add --dev pytest-cov

# Run Python code
uv run python src/main.py

# Run tests
uv run pytest

# Run linter
uv run ruff check .

# Run type checker
uv run mypy .

# Format code
uv run ruff format .
```

### Frontend (Next.js)

```bash
cd frontend

# Install dependencies (if needed)
npm install
# or
pnpm install
# or
yarn install

# Start development server
npm run dev
# or
pnpm dev
# or
yarn dev

# Build for production
npm run build
# or
pnpm build
# or
yarn build

# Run linter
npm run lint
# or
pnpm lint
# or
yarn lint
```

## VS Code Integration

The generated `.vscode/settings.json` includes:

- **Python**: Points to `backend/.venv/bin/python` for IntelliSense
- **TypeScript**: Uses workspace TypeScript from `frontend/node_modules/`
- **Formatting**:
  - Python files: Ruff formatter
  - JS/TS files: Prettier
- **Auto-fix**: ESLint and Ruff on save

## Common Tasks

### Running Backend API

```bash
cd backend
uv add fastapi uvicorn

# Create src/main.py
cat > src/main.py << 'EOF'
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def read_root():
    return {"message": "Hello from FastAPI!"}

@app.get("/api/health")
def health_check():
    return {"status": "ok"}
EOF

# Run the server
uv run uvicorn src.main:app --reload
```

API will be available at http://localhost:8000

### Connecting Frontend to Backend

1. Update `frontend/.env.local`:
   ```env
   NEXT_PUBLIC_API_URL=http://localhost:8000
   ```

2. Create API client in `frontend/src/lib/api.ts`:
   ```typescript
   const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

   export async function fetchData() {
       const response = await fetch(`${API_URL}/api/data`);
       return response.json();
   }
   ```

3. Use in your components:
   ```typescript
   import { fetchData } from '@/lib/api';

   export default async function Page() {
       const data = await fetchData();
       return <div>{JSON.stringify(data)}</div>;
   }
   ```

### Database Setup (Example with PostgreSQL)

```bash
cd backend

# Add PostgreSQL driver
uv add psycopg2-binary

# Add ORM (optional)
uv add sqlalchemy

# Update .env.local
echo "DATABASE_URL=postgresql://user:password@localhost/dbname" > .env.local
```

## Troubleshooting

### Python virtual environment not recognized

Make sure you've opened VS Code in the project root (not in `backend/` or `frontend/`).

Reload VS Code: `Ctrl+Shift+P` → "Developer: Reload Window"

### Next.js TypeScript errors

```bash
cd frontend
rm -rf .next node_modules
npm install
npm run dev
```

### Port already in use

Backend (Python):
```bash
# Change port in uvicorn command
uv run uvicorn src.main:app --reload --port 8001
```

Frontend (Next.js):
```bash
# Change port in package.json or use:
npm run dev -- -p 3001
```

## Customization

### Add more development tools (Python)

```bash
cd backend
uv add --dev black isort pylint
```

### Add UI libraries (Next.js)

```bash
cd frontend
npm install @radix-ui/react-dialog class-variance-authority clsx tailwind-merge
# or
pnpm add @radix-ui/react-dialog class-variance-authority clsx tailwind-merge
```

### Modify .gitignore

The unified `.gitignore` uses path prefixes:
- Common entries (env vars, OS files): Applied to root
- Python-specific: Prefixed with `backend/`
- Next.js-specific: Prefixed with `frontend/`

To modify, edit the templates in `templates/gitignore/`.

## Related Scripts

- [Python Setup](../python/README.md) - Python-only projects
- [Next.js Setup](../nextjs/README.md) - Next.js-only projects

## Contributing

When adding new features to the fullstack script:
1. Update template files in `templates/`
2. Update this README
3. Test with a new project from scratch
4. Submit a pull request

## License

Same as the parent repository.
