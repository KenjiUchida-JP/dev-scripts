## 開発環境

このプロジェクトは [dev-scripts](https://github.com/KenjiUchida-JP/dev-scripts) の `nodejs/setup-project.sh` で Node.js 開発環境が構築済みです。
コードの実行やパッケージの追加は、以下のルールに従ってください。

### Node.js

- スクリプトの実行: `pnpm run start`（`src/index.ts` を tsx で直接実行、ビルド不要）— npm/yarn/bun を選んだ場合は対応するコマンドに読み替え
- パッケージの追加: `pnpm add <package>`
- 開発用パッケージの追加: `pnpm add -D <package>`
- Node バージョンは `.node-version` / `.nvmrc` で固定済み（fnm/nvm が自動切替）
- パッケージマネージャは `package.json` の `packageManager` フィールドで固定済み（`corepack enable` が前提）
- Lint: `pnpm run lint`
- 型チェック: `pnpm run typecheck`
- テスト: `pnpm run test`

### 注意事項

- `node_modules/` を手動で削除・再作成しないこと（壊れた場合は `pnpm install` で復元できます）
- パッケージを追加・変更した場合、ロックファイル（`pnpm-lock.yaml` 等）の変更もコミットに含めること
