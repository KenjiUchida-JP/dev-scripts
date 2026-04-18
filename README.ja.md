# dev-scripts

[🇺🇸 English](./README.md) | 🇯🇵 日本語

開発環境のセットアップと自動化のためのスクリプト集です。

すべてのスクリプトは **カレントディレクトリで実行** されます。対象のプロジェクトフォルダに `cd` してからスクリプトを起動してください。

## 1. クイックスタート

### Python プロジェクト

プロジェクトディレクトリでセットアップを実行：

```bash
mkdir my-project && cd my-project
bash <(curl -fsSL https://raw.githubusercontent.com/KenjiUchida-JP/dev-scripts/main/python/setup-project.sh)
```

**前提条件:** [uv](https://docs.astral.sh/uv/)

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### Next.js プロジェクト

```bash
mkdir my-app && cd my-app
bash <(curl -fsSL https://raw.githubusercontent.com/KenjiUchida-JP/dev-scripts/main/nextjs/setup-project.sh)
```

**前提条件:** [Node.js](https://nodejs.org/)（[nvm](https://github.com/nvm-sh/nvm) または [fnm](https://github.com/Schniz/fnm) の使用を推奨）

### フルスタックプロジェクト（Python + Next.js）

```bash
mkdir my-fullstack && cd my-fullstack
bash <(curl -fsSL https://raw.githubusercontent.com/KenjiUchida-JP/dev-scripts/main/fullstack/setup-project.sh)
```

**前提条件:** `uv` と Node.js の両方

## 2. 挙動

### 実行モデル

- スクリプトは常に **カレントディレクトリ** に対して動作します
- プロジェクト名はカレントディレクトリ名がデフォルトになり、対話入力で上書き可能
- 致命的な衝突（`.venv/`、`pyproject.toml`、`node_modules/`、`package.json` 等）を検出した場合は即座に中止
- 通常スクリプトが生成するファイルは、**既存があれば温存** します:
  - `README.md`
  - `.gitignore`
  - `.vscode/settings.json`
  - `.git/`（既存があれば `git init` をスキップ）

### Python プロジェクト

- Python バージョン、プロジェクトタイプ（app/lib）の対話的セットアップ
- 仮想環境（`.venv/`）
- ツール設定を含む `pyproject.toml`
- 適切なデフォルト設定の `.gitignore`（既存があればスキップ）
- `__init__.py` を含む `src/` ディレクトリ
- `conftest.py` を含む `tests/` ディレクトリ（開発ツール選択時）
- Python インタープリタパスを含む `.vscode/settings.json`（既存があればスキップ）
- 初期化された Git リポジトリ（`.git/` 既存ならスキップ）

### Next.js プロジェクト

- Node.js バージョン、Next.js バージョン、パッケージマネージャの対話的セットアップ
- TypeScript と `src/` ディレクトリを使用した Next.js プロジェクト
- プロジェクトテンプレートで上書きされる `.gitignore`（既存があればスキップ）
- Prettier と ESLint 設定を含む `.vscode/settings.json`（既存があればスキップ）
- Node バージョンファイル（`.nvmrc`、`.node-version`）

### フルスタックプロジェクト

- カレントディレクトリ直下に `backend/` と `frontend/` を作成するモノレポ構造
- パスプレフィックスを持つ統合された `.gitignore`（既存があればスキップ）
- 両言語用にマージされた `.vscode/settings.json`（既存があればスキップ）
- Python バージョン、Node.js バージョン、Next.js バージョンの対話的セットアップ
- Python と Node.js の両方の開発環境
- `src/` ディレクトリ構造を持つフロントエンド
- `.env` ファイルは事前設定なし（プロジェクトに応じて作成してください）

## 3. ライセンス

MIT License
