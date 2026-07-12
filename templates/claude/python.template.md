## 開発環境

このプロジェクトは [dev-scripts](https://github.com/KenjiUchida-JP/dev-scripts) の `python/setup-project.sh` で Python 開発環境が構築済みです。
コードの実行やパッケージの追加は、以下のルールに従ってください。

### Python

- Python の実行は **`uv run python`** を使うこと（`.venv` を直接 activate しない）
- スクリプトの実行: `uv run python src/...`（パスはプロジェクトに合わせて読み替え）
- パッケージの追加: `uv add <package>`
- 開発用パッケージの追加: `uv add --dev <package>`
- バージョンは `.python-version` で固定済み
- Lint: `uv run ruff check .`
- 型チェック: `uv run mypy .`
- テスト: `uv run pytest`

### 注意事項

- `.venv/` を手動で削除・再作成しないこと（壊れた場合は `uv sync` で復元できます）
- パッケージを追加・変更した場合、ロックファイル（`uv.lock`）の変更もコミットに含めること
