# dev-scripts

開発環境のセットアップや自動化のためのスクリプト集です。

## 1. はじめに

このリポジトリには、開発プロジェクトの初期セットアップを自動化するスクリプトが含まれています。

## 2. セットアップ

リポジトリをクローンした後、以下のコマンドを実行して Git hooks を設定してください。

```bash
git clone https://github.com/YOUR_USERNAME/dev-scripts.git
cd dev-scripts
./scripts/setup-hooks.sh
```

## 3. 含まれるスクリプト

### 🐍 Python プロジェクトセットアップ

`uv` を使用して Python プロジェクトを自動構築します。

```bash
./python/setup-project.sh
```

**機能:**
- Python 環境の自動セットアップ
- 開発ツール（ruff, mypy, pytest）の設定
- `.gitignore` の自動生成
- `pyproject.toml` へのツール設定追記

**前提条件:**
- [uv](https://docs.astral.sh/uv/) がインストール済みであること

## 4. ディレクトリ構成

```
dev-scripts/
├── python/
│   ├── setup-project.sh      # Python プロジェクトセットアップ
│   ├── build.sh              # テンプレート同期ビルド
│   └── .gitignore.template   # .gitignore テンプレート
├── hooks/
│   └── pre-commit            # Git pre-commit フック
├── scripts/
│   └── setup-hooks.sh        # Git hooks セットアップ
└── .github/
    └── workflows/
        └── check-build.yml   # CI: テンプレート同期チェック
```

## 5. 開発者向け情報

### Git Hooks について

`hooks/` ディレクトリ内のスクリプトは、`./scripts/setup-hooks.sh` を実行することで `.git/hooks/` にシンボリックリンクとして設定されます。

**現在のフック:**
- `pre-commit`: コミット前に `.gitignore.template` と `setup-project.sh` の同期をチェック

### テンプレートの更新

`.gitignore.template` を編集した場合、コミット時に自動で `setup-project.sh` 内のヒアドキュメントが更新されます。手動で更新する場合は以下を実行してください。

```bash
./python/build.sh
```

## 6. ライセンス

MIT License
