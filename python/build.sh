#!/usr/bin/env bash
# ==================================================
# Build Script
# .gitignore.template を setup-project.sh に埋め込む
# ==================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_FILE="${SCRIPT_DIR}/.gitignore.template"
TARGET_FILE="${SCRIPT_DIR}/setup-project.sh"

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# --------------------------------------------------
# テンプレートファイルの存在チェック
# --------------------------------------------------
if [[ ! -f "$TEMPLATE_FILE" ]]; then
    echo -e "${RED}エラー:${NC} $TEMPLATE_FILE が見つかりません" >&2
    exit 1
fi

if [[ ! -f "$TARGET_FILE" ]]; then
    echo -e "${RED}エラー:${NC} $TARGET_FILE が見つかりません" >&2
    exit 1
fi

# --------------------------------------------------
# テンプレート内容を読み込み
# --------------------------------------------------
TEMPLATE_CONTENT=$(cat "$TEMPLATE_FILE")

# --------------------------------------------------
# 新しい generate_gitignore 関数を生成
# --------------------------------------------------
NEW_FUNCTION=$(cat << 'FUNC_START'
# --------------------------------------------------
# .gitignore生成関数
# --------------------------------------------------
generate_gitignore() {
    local template_file="${SCRIPT_DIR}/.gitignore.template"
    if [[ -f "$template_file" ]]; then
        cat "$template_file"
    else
        # curl実行時のフォールバック（自動生成: build.sh）
        cat << 'GITIGNORE_EOF'
FUNC_START
)

NEW_FUNCTION="${NEW_FUNCTION}
${TEMPLATE_CONTENT}
GITIGNORE_EOF
    fi
}"

# --------------------------------------------------
# setup-project.sh を更新
# マーカー: # --- BEGIN GITIGNORE_FUNC --- と # --- END GITIGNORE_FUNC ---
# --------------------------------------------------

# マーカーが存在するか確認
if ! grep -q "# --- BEGIN GITIGNORE_FUNC ---" "$TARGET_FILE"; then
    echo -e "${RED}エラー:${NC} マーカーが見つかりません。setup-project.sh にマーカーを追加してください" >&2
    exit 1
fi

# 一時ファイルを作成
TEMP_FILE=$(mktemp)

# マーカー間を置換
awk -v new_func="$NEW_FUNCTION" '
    /# --- BEGIN GITIGNORE_FUNC ---/ {
        print "# --- BEGIN GITIGNORE_FUNC ---"
        print new_func
        skip = 1
        next
    }
    /# --- END GITIGNORE_FUNC ---/ {
        print "# --- END GITIGNORE_FUNC ---"
        skip = 0
        next
    }
    !skip { print }
' "$TARGET_FILE" > "$TEMP_FILE"

# --------------------------------------------------
# 差分チェックと更新
# --------------------------------------------------
if diff -q "$TARGET_FILE" "$TEMP_FILE" > /dev/null 2>&1; then
    echo -e "${YELLOW}変更なし:${NC} $TARGET_FILE は最新です"
    rm "$TEMP_FILE"
else
    mv "$TEMP_FILE" "$TARGET_FILE"
    chmod +x "$TARGET_FILE"
    echo -e "${GREEN}更新完了:${NC} $TARGET_FILE を更新しました"
fi
