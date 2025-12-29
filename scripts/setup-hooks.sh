#!/usr/bin/env bash
# ==================================================
# Git Hooks Setup Script
# hooks/ ディレクトリの内容を .git/hooks/ にシンボリックリンク
# ==================================================

set -e

# カラー定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# リポジトリのルートディレクトリを取得
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOKS_DIR="${REPO_ROOT}/hooks"
GIT_HOOKS_DIR="${REPO_ROOT}/.git/hooks"

# .git ディレクトリの存在確認
if [[ ! -d "${REPO_ROOT}/.git" ]]; then
    echo -e "${RED}エラー:${NC} .git ディレクトリが見つかりません"
    echo "このスクリプトはリポジトリのルートから実行してください"
    exit 1
fi

# hooks ディレクトリの存在確認
if [[ ! -d "$HOOKS_DIR" ]]; then
    echo -e "${RED}エラー:${NC} hooks/ ディレクトリが見つかりません"
    exit 1
fi

echo -e "${GREEN}🔧 Git hooks をセットアップ中...${NC}"

# hooks/ 内の各ファイルに対してシンボリックリンクを作成
for hook in "$HOOKS_DIR"/*; do
    if [[ -f "$hook" ]]; then
        hook_name=$(basename "$hook")
        target="${GIT_HOOKS_DIR}/${hook_name}"

        # 既存のファイル/リンクがあれば削除
        if [[ -e "$target" || -L "$target" ]]; then
            rm "$target"
        fi

        # シンボリックリンクを作成
        ln -sf "../../hooks/${hook_name}" "$target"
        echo -e "  ${GREEN}✓${NC} ${hook_name}"
    fi
done

echo ""
echo -e "${GREEN}✅ Git hooks のセットアップが完了しました！${NC}"
