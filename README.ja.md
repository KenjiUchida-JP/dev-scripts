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

- プロジェクト名とNode.jsバージョンの対話的セットアップ
- TypeScript を使用した Next.js プロジェクト
- 適切なデフォルト設定の `.gitignore`
- Prettier と ESLint 設定を含む `.vscode/settings.json`
- Node バージョンファイル（`.nvmrc`、`.node-version`）
- 初期化された Git リポジトリ

### フルスタックプロジェクト

- `frontend/` と `backend/` ディレクトリを持つモノレポ構造
- パスプレフィックスを持つ統合された `.gitignore`
- 両言語用にマージされた `.vscode/settings.json`
- Python と Node.js の両方の開発環境

## 3. コントリビューター向け

このリポジトリに貢献したい場合は、クローンして Git フックをセットアップしてください：

```bash
git clone https://github.com/KenjiUchida-JP/dev-scripts.git
cd dev-scripts
./scripts/setup-hooks.sh
```

### ディレクトリ構造

```
dev-scripts/
├── templates/                # 一元化されたテンプレート保管場所
│   ├── gitignore/           # モジュール化された .gitignore テンプレート
│   │   ├── base.template    # 共通（IDE、OS、環境変数）
│   │   ├── python.template  # Python 固有
│   │   └── nextjs.template  # Next.js 固有
│   └── vscode/              # VS Code 設定テンプレート
│       ├── python.settings.json
│       ├── nextjs.settings.json
│       └── fullstack.settings.json
├── python/
│   ├── setup-project.sh     # Python プロジェクトセットアップ
│   └── build.sh             # テンプレート同期ビルド
├── nextjs/
│   ├── setup-project.sh     # Next.js プロジェクトセットアップ
│   └── build.sh             # テンプレート同期ビルド
├── fullstack/
│   └── setup-project.sh     # フルスタックプロジェクトセットアップ
├── scripts/
│   ├── setup-hooks.sh       # Git フックインストーラー
│   └── lib/                 # 共有ライブラリ関数
│       ├── colors.sh        # カラー出力ヘルパー
│       ├── validators.sh    # 入力バリデーション
│       └── gitignore-builder.sh  # テンプレート構成
├── hooks/
│   └── pre-commit           # Git pre-commit フック
└── .github/
    └── workflows/
        └── check-build.yml  # CI: テンプレート同期チェック
```

### Git フックについて

`hooks/` ディレクトリ内のスクリプトは、`./scripts/setup-hooks.sh` を実行することで `.git/hooks/` へのシンボリックリンクとして設定されます。

**現在のフック:**
- `pre-commit`: コミット前に全テンプレートを同期

### テンプレートの更新

`templates/` 内のテンプレートを編集すると、コミット時にセットアップスクリプトが自動的に更新されます。手動で更新する場合：

```bash
./python/build.sh
./nextjs/build.sh
```

## 4. ライセンス

MIT License
