# dev-scripts

[🇺🇸 English](./README.md) | 🇯🇵 日本語

開発環境のセットアップと自動化のためのスクリプト集です。

## 1. クイックスタート

### Python プロジェクト

Python プロジェクトを即座に作成：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/KenjiUchida-JP/dev-scripts/main/python/setup-project.sh)
```

**前提条件:** [uv](https://docs.astral.sh/uv/)

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### Next.js プロジェクト

Next.js プロジェクトを作成：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/KenjiUchida-JP/dev-scripts/main/nextjs/setup-project.sh)
```

**前提条件:** [Node.js](https://nodejs.org/)（[nvm](https://github.com/nvm-sh/nvm) または [fnm](https://github.com/Schniz/fnm) の使用を推奨）

### フルスタックプロジェクト（Python + Next.js）

バックエンドとフロントエンドの両方を含むフルスタックプロジェクトを作成：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/KenjiUchida-JP/dev-scripts/main/fullstack/setup-project.sh)
```

**前提条件:** `uv` と Node.js の両方

## 2. 機能

### Python プロジェクト

- プロジェクト名、Pythonバージョン、タイプ（app/lib）の対話的セットアップ
- 仮想環境（`.venv/`）
- ツール設定を含む `pyproject.toml`
- 適切なデフォルト設定の `.gitignore`
- `__init__.py` を含む `src/` ディレクトリ
- `conftest.py` を含む `tests/` ディレクトリ（開発ツール選択時）
- Pythonインタープリタパスを含む `.vscode/settings.json`
- 初期化された Git リポジトリ

### Next.js プロジェクト

- プロジェクト名、Node.jsバージョン、Next.jsバージョンの対話的セットアップ
- TypeScript と `src/` ディレクトリを使用した Next.js プロジェクト
- 適切なデフォルト設定の `.gitignore`
- Prettier と ESLint 設定を含む `.vscode/settings.json`
- Node バージョンファイル（`.nvmrc`、`.node-version`）
- 初期化された Git リポジトリ

### フルスタックプロジェクト

- `frontend/` と `backend/` ディレクトリを持つモノレポ構造
- パスプレフィックスを持つ統合された `.gitignore`
- 両言語用にマージされた `.vscode/settings.json`
- Pythonバージョン、Node.jsバージョン、Next.jsバージョンの対話的セットアップ
- Python と Node.js の両方の開発環境
- `src/` ディレクトリ構造を持つフロントエンド
- `.env` ファイルは事前設定なし（プロジェクトに応じて作成してください）

## 3. ライセンス

MIT License
