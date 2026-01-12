# フルスタックプロジェクトセットアップ

[🇺🇸 English](./README.md) | 🇯🇵 日本語

Python（バックエンド）と Next.js（フロントエンド）を組み合わせたフルスタックプロジェクトの自動セットアップスクリプトです。

## 機能

- **Python バックエンド**
  - [uv](https://github.com/astral-sh/uv)（高速なPythonパッケージマネージャー）で管理
  - ruff、mypy、pytest で事前設定済み
  - `src/` と `tests/` を含む整理されたプロジェクト構造
  - 適切な Python パスで VS Code と統合

- **Next.js フロントエンド**
  - TypeScript を使用した最新の Next.js
  - スタイリング用の Tailwind CSS
  - コード品質のための ESLint
  - 一貫したフォーマットのための Prettier
  - 自動パッケージマネージャー検出（npm、pnpm、または yarn）

- **統合設定**
  - バックエンドとフロントエンドの両方にパスプレフィックスを持つ単一の `.gitignore`
  - シームレスな開発のためにマージされた VS Code 設定
  - ルートレベルの Git リポジトリ

## 前提条件

### 必須

- **Python と uv**: Python パッケージ管理のために uv をインストール
  ```bash
  curl -LsSf https://astral.sh/uv/install.sh | sh
  ```

- **Node.js**: Node.js をインストール（v18 以降推奨）
  - nvm を使用: `nvm install --lts`
  - fnm を使用: `fnm install --lts`
  - 直接ダウンロード: https://nodejs.org/

### オプション

- **pnpm** または **yarn**: 代替パッケージマネージャー（npm より高速）
  ```bash
  npm install -g pnpm
  # または
  npm install -g yarn
  ```

## クイックスタート

### 1. セットアップスクリプトを実行

```bash
# fullstack ディレクトリから
./setup-project.sh

# またはリポジトリルートから
./fullstack/setup-project.sh
```

### 2. プロジェクト名を入力

```
📦 Project name: my-awesome-app
```

### 3. セットアップの完了を待つ

スクリプトは以下を実行します：
1. プロジェクトディレクトリ構造を作成
2. 統合された `.gitignore` を生成
3. VS Code 設定を構成
4. uv で Python バックエンドをセットアップ
5. Next.js フロントエンドをセットアップ
6. Git リポジトリを初期化

## プロジェクト構造

セットアップ後、プロジェクトは以下の構造になります：

```
my-awesome-app/
├── .gitignore              # バックエンドとフロントエンドの両方の統合 gitignore
├── .vscode/
│   └── settings.json       # マージされた VS Code 設定
│
├── backend/                # Python プロジェクト
│   ├── pyproject.toml      # Python 依存関係と設定
│   ├── .venv/              # 仮想環境
│   ├── src/
│   │   └── __init__.py
│   └── tests/
│       ├── __init__.py
│       └── conftest.py
│
└── frontend/               # Next.js プロジェクト
    ├── package.json
    ├── tsconfig.json
    ├── .prettierrc
    ├── .env.example
    ├── app/
    │   ├── page.tsx
    │   └── layout.tsx
    └── public/
```

## 開発ワークフロー

### バックエンド（Python）

```bash
cd backend

# 依存関係を追加
uv add fastapi uvicorn

# 開発用依存関係を追加
uv add --dev pytest-cov

# Python コードを実行
uv run python src/main.py

# テストを実行
uv run pytest

# リンターを実行
uv run ruff check .

# 型チェッカーを実行
uv run mypy .

# コードをフォーマット
uv run ruff format .
```

### フロントエンド（Next.js）

```bash
cd frontend

# 依存関係をインストール（必要な場合）
npm install
# または
pnpm install
# または
yarn install

# 開発サーバーを起動
npm run dev
# または
pnpm dev
# または
yarn dev

# プロダクション用にビルド
npm run build
# または
pnpm build
# または
yarn build

# リンターを実行
npm run lint
# または
pnpm lint
# または
yarn lint
```

## VS Code 統合

生成された `.vscode/settings.json` には以下が含まれます：

- **Python**: IntelliSense のために `backend/.venv/bin/python` を指定
- **TypeScript**: `frontend/node_modules/` のワークスペース TypeScript を使用
- **フォーマット**:
  - Python ファイル: Ruff フォーマッター
  - JS/TS ファイル: Prettier
- **自動修正**: 保存時に ESLint と Ruff

## よくあるタスク

### バックエンド API の実行

```bash
cd backend
uv add fastapi uvicorn

# src/main.py を作成
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

# サーバーを実行
uv run uvicorn src.main:app --reload
```

API は http://localhost:8000 で利用可能になります

### フロントエンドとバックエンドの接続

1. `frontend/.env.local` を更新：
   ```env
   NEXT_PUBLIC_API_URL=http://localhost:8000
   ```

2. `frontend/app/lib/api.ts` に API クライアントを作成：
   ```typescript
   const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

   export async function fetchData() {
       const response = await fetch(`${API_URL}/api/data`);
       return response.json();
   }
   ```

3. コンポーネントで使用：
   ```typescript
   import { fetchData } from '@/lib/api';

   export default async function Page() {
       const data = await fetchData();
       return <div>{JSON.stringify(data)}</div>;
   }
   ```

### データベースセットアップ（PostgreSQL の例）

```bash
cd backend

# PostgreSQL ドライバーを追加
uv add psycopg2-binary

# ORM を追加（オプション）
uv add sqlalchemy

# .env.local を更新
echo "DATABASE_URL=postgresql://user:password@localhost/dbname" > .env.local
```

## トラブルシューティング

### Python 仮想環境が認識されない

プロジェクトルートで VS Code を開いていることを確認してください（`backend/` または `frontend/` 内ではなく）。

VS Code をリロード：`Ctrl+Shift+P` → "Developer: Reload Window"

### Next.js TypeScript エラー

```bash
cd frontend
rm -rf .next node_modules
npm install
npm run dev
```

### ポートが既に使用中

バックエンド（Python）：
```bash
# uvicorn コマンドでポートを変更
uv run uvicorn src.main:app --reload --port 8001
```

フロントエンド（Next.js）：
```bash
# package.json でポートを変更するか、以下を使用：
npm run dev -- -p 3001
```

## カスタマイズ

### さらに開発ツールを追加（Python）

```bash
cd backend
uv add --dev black isort pylint
```

### UI ライブラリを追加（Next.js）

```bash
cd frontend
npm install @radix-ui/react-dialog class-variance-authority clsx tailwind-merge
# または
pnpm add @radix-ui/react-dialog class-variance-authority clsx tailwind-merge
```

### .gitignore を変更

統合された `.gitignore` はパスプレフィックスを使用します：
- 共通エントリ（環境変数、OS ファイル）：ルートに適用
- Python 固有：`backend/` でプレフィックス
- Next.js 固有：`frontend/` でプレフィックス

変更するには、`templates/gitignore/` のテンプレートを編集してください。

## 関連スクリプト

- [Python セットアップ](../python/README.md) - Python のみのプロジェクト
- [Next.js セットアップ](../nextjs/README.md) - Next.js のみのプロジェクト

## コントリビューション

フルスタックスクリプトに新機能を追加する場合：
1. `templates/` のテンプレートファイルを更新
2. この README を更新
3. 新規プロジェクトでゼロからテスト
4. プルリクエストを送信

## ライセンス

親リポジトリと同じです。
