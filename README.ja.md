# dev-scripts

[🇺🇸 English](./README.md) | 🇯🇵 日本語

カレントディレクトリに、Python または Node.js の独立したプロジェクト単位の実行環境をサクッと構築するスクリプト集です。Claude Code のようなツールが、グローバル環境を汚さずローカルなサンドボックス内でスクリプトを実行できるようにするためのものです。

このスクリプトは**アプリケーションのひな形は作りません**。フレームワークもスターターUIも、DB接続や認証プロバイダ用の `.env` サンプルもありません。用意するのは動くインタープリタ、パッケージマネージャ、そしてコードを書く `src/` フォルダだけです。

すべてのスクリプトは **カレントディレクトリで実行** されます。対象のプロジェクトフォルダに `cd` してからスクリプトを起動してください。

## 1. クイックスタート

### Python 環境

プロジェクトディレクトリでセットアップを実行：

```bash
mkdir my-project && cd my-project
bash <(curl -fsSL https://raw.githubusercontent.com/KenjiUchida-JP/dev-scripts/main/python/setup-project.sh)
```

**前提条件:** [uv](https://docs.astral.sh/uv/)

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### Node.js 環境

```bash
mkdir my-scripts && cd my-scripts
bash <(curl -fsSL https://raw.githubusercontent.com/KenjiUchida-JP/dev-scripts/main/nodejs/setup-project.sh)
```

**前提条件:** [Node.js](https://nodejs.org/)（[nvm](https://github.com/nvm-sh/nvm) または [fnm](https://github.com/Schniz/fnm) の使用を推奨）

## 2. 挙動

### 実行モデル

- スクリプトは常に **カレントディレクトリ** に対して動作します
- プロジェクト名はディレクトリ名から自動採用します（プロジェクト名の対話入力はありません）
- 致命的な衝突（`.venv/`、`pyproject.toml`、`node_modules/`、`package.json` 等）を検出した場合は即座に中止
- 通常スクリプトが生成するファイルは、**既存があれば温存** します:
  - `README.md`
  - `.gitignore`
  - `.vscode/settings.json`
  - `CLAUDE.md.temp`
  - `.git/`（既存があれば `git init` をスキップ）

### Python 環境

- Python バージョン、プロジェクトタイプ（app/lib）の対話的セットアップ
- [uv](https://docs.astral.sh/uv/) が管理する仮想環境（`.venv/`）
- ツール設定を含む `pyproject.toml`
- 適切なデフォルト設定の `.gitignore`（既存があればスキップ）
- `__init__.py` を含む `src/` ディレクトリ
- `conftest.py` を含む `tests/` ディレクトリ（開発ツール選択時）
- オプションの開発ツール: ruff、mypy、pytest
- Python インタープリタパスを含む `.vscode/settings.json`（既存があればスキップ）
- Claude Code 向けのプロジェクト運用ルールを記載した `CLAUDE.md.temp`（既存があればスキップ）
- 初期化された Git リポジトリ（`.git/` 既存ならスキップ）

`uv run python src/...` でスクリプトを実行できます。`source .venv/bin/activate` を手動で叩く必要はありません。

### Node.js 環境

- Node.js バージョン、パッケージマネージャ（npm/pnpm/yarn/bun）の対話的セットアップ — **pnpm がインストール済みならデフォルトで選択されます**
- カレントディレクトリに `package.json` とローカルの `node_modules/`
- TypeScript + [tsx](https://github.com/privatenumber/tsx) により、ビルドなしで `.ts` ファイルを直接実行可能
- `src/index.ts` のエントリスタブ
- オプションの開発ツール: eslint、prettier、vitest
- 適切なデフォルト設定の `.gitignore`（既存があればスキップ）
- `.vscode/settings.json`（既存があればスキップ）
- Claude Code 向けのプロジェクト運用ルールを記載した `CLAUDE.md.temp`（既存があればスキップ）
- バージョンマネージャ検出時の `.nvmrc` / `.node-version`
- pnpm または yarn を選んだ場合、`package.json` に `packageManager` フィールド（`pnpm@<version>` 等）を書き込み、[corepack](https://nodejs.org/api/corepack.html) が同じパッケージマネージャの使用を強制するようにします

`pnpm run start`（または使用するパッケージマネージャの対応コマンド）でスクリプトを実行できます。

## 3. 補足事項・ハマりどころ

### fnm には自己アップデートコマンドが無い

`fnm` には `fnm update` のような自己アップデート機能が無いので、公式インストーラを再実行してアップデートします。バイナリがその場で上書きされるだけなので、シェル設定の再変更は不要です:

```bash
curl -fsSL https://fnm.vercel.app/install | bash
```

### `packageManager` の固定を実際に効かせるには corepack の有効化が必要

pnpm または yarn を選んだ場合、セットアップスクリプトは `package.json` に `"packageManager": "pnpm@<version>"` のような形でバージョンを固定します。ただしこの固定は [corepack](https://nodejs.org/api/corepack.html) が有効化されていて初めて**実際に強制力を持ちます**：

```bash
corepack enable
```

Node.js には corepack 自体は最初から同梱されていますが、デフォルトでは有効化されていません。これを一度実行しておかないと、`packageManager` はただのメタデータで終わってしまい、実際には `PATH` 上で最初に見つかった pnpm/yarn がそのまま使われます。fnm/nvm で新しい Node.js バージョンを追加インストールした場合、そのバージョンにはまだシムが入っていないので、`corepack enable` をそのバージョンに対してもう一度実行してください。

### pnpm のビルドスクリプトブロックについて

最近の pnpm（v10以降）は、サプライチェーン対策としてデフォルトで依存パッケージのライフサイクルスクリプト（`esbuild` の postinstall など）をブロックします。その結果、パッケージ自体のインストールは成功しているのに `pnpm add`／`pnpm install` が **0以外の終了コード** を返すことがあります。セットアップスクリプトはこれを自動的に処理しています（必要に応じて `pnpm approve-builds --all` を実行）。セットアップ中に `[ERR_PNPM_IGNORED_BUILDS]` という表示が出ても想定内で、特に対応は不要です。

### 1台のPCに複数のパッケージマネージャが混在していても問題ない。ただし1プロジェクト内で混ぜるのはNG

同じPCに npm と pnpm（や他のツール）が両方入っているのはごく普通の状態です。npm は Node.js に標準同梱されているため、そこに別のパッケージマネージャを追加インストールしても衝突は起きません。実際に問題になるのは、**あるプロジェクトのロックファイルを生成したのとは違うパッケージマネージャを、同じプロジェクト内で実行してしまうこと**（例: `pnpm-lock.yaml` があるプロジェクトで `npm install` を実行するなど）です。1プロジェクトにつき1つのパッケージマネージャに統一してください——上記の `packageManager` フィールドは、corepack を有効化しておけばこれを強制する助けになります。

## 4. ライセンス

MIT License
