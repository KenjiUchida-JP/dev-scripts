#!/usr/bin/env bash
# ==================================================
# Python Project Setup Script
# uvを使用したPython環境の自動構築
# ==================================================

set -e

# --------------------------------------------------
# カラー定義
# --------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --------------------------------------------------
# ヘルパー関数
# --------------------------------------------------
print_header() {
    echo -e "\n${CYAN}🐍 Python Project Setup${NC}"
    echo "=================================================="
}

print_step() {
    echo -e "${BLUE}➜${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# バージョン文字列からpyXXX形式に変換（例: 3.14.2 → py314）
get_py_version() {
    local version="$1"
    local major minor
    major=$(echo "$version" | cut -d. -f1)
    minor=$(echo "$version" | cut -d. -f2)
    echo "py${major}${minor}"
}

# バージョン文字列からX.XX形式を取得（例: 3.14.2 → 3.14）
get_major_minor() {
    local version="$1"
    echo "$version" | cut -d. -f1,2
}

# バージョン形式のバリデーション
validate_version() {
    local version="$1"
    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
        return 1
    fi
    return 0
}

# プロジェクト名のバリデーション
validate_project_name() {
    local name="$1"
    # 空文字チェック
    if [[ -z "$name" ]]; then
        return 1
    fi
    # 有効な文字のみ（英数字、ハイフン、アンダースコア）
    if [[ ! "$name" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]; then
        return 1
    fi
    return 0
}

# 最新のPythonバージョンを取得
get_latest_python_version() {
    local version
    version=$(uv python list 2>/dev/null | grep -E "^cpython-[0-9]+\.[0-9]+\.[0-9]+-" | grep -v "freethreaded" | head -1 | sed 's/cpython-\([0-9.]*\)-.*/\1/')
    if [[ -z "$version" ]]; then
        # フォールバック: 取得できなかった場合は3.13を使用
        echo "3.13"
    else
        echo "$version"
    fi
}

# --------------------------------------------------
# スクリプトのディレクトリを取得
# --------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- BEGIN GITIGNORE_FUNC ---
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
# ==================================================
# Python Project .gitignore Template
# ==================================================

# --------------------------------------------------
# Byte-compiled / Optimized / DLL files
# --------------------------------------------------
__pycache__/
*.py[cod]
*$py.class
*.so

# --------------------------------------------------
# Virtual Environments
# --------------------------------------------------
.venv/
venv/
env/
ENV/

# --------------------------------------------------
# Distribution / Packaging
# --------------------------------------------------
build/
dist/
*.egg-info/
*.egg
wheels/
MANIFEST

# --------------------------------------------------
# Testing / Coverage
# --------------------------------------------------
.pytest_cache/
.coverage
.coverage.*
htmlcov/
.tox/
.nox/

# --------------------------------------------------
# Type Checkers / Linters
# --------------------------------------------------
.mypy_cache/
.ruff_cache/
.pytype/

# --------------------------------------------------
# Environment Variables / Secrets
# --------------------------------------------------
.env
.env.local
.env.*.local
.env.prod
.env.dev
.env.test
*.pem

# --------------------------------------------------
# IDE / Editor
# --------------------------------------------------
.idea/
.cursor/
.claude/
.vscode/
*.swp
*.swo
*~

# --------------------------------------------------
# OS Generated
# --------------------------------------------------
.DS_Store
Thumbs.db

# --------------------------------------------------
# Project Specific
# --------------------------------------------------
docs/
tmp/
GITIGNORE_EOF
    fi
}
# --- END GITIGNORE_FUNC ---

# --------------------------------------------------
# pyproject.tomlにツール設定を追記
# --------------------------------------------------
append_tool_config() {
    local pyproject_file="$1"
    local py_version="$2"
    local major_minor="$3"

    cat >> "$pyproject_file" << TOML_EOF

# --------------------------------------------------
# Tool Configuration
# --------------------------------------------------

[tool.ruff]
target-version = "${py_version}"
line-length = 88

[tool.ruff.lint]
select = ["E", "W", "F", "I", "B", "C4", "UP", "RUF"]

[tool.mypy]
python_version = "${major_minor}"
strict = true

[tool.pytest.ini_options]
testpaths = ["tests"]
TOML_EOF
}

# --------------------------------------------------
# メイン処理
# --------------------------------------------------
main() {
    print_header

    # --------------------------------------------------
    # 1. プロジェクト名の入力
    # --------------------------------------------------
    while true; do
        echo -ne "${CYAN}📦 プロジェクト名: ${NC}"
        read -r PROJECT_NAME
        if validate_project_name "$PROJECT_NAME"; then
            break
        else
            print_error "無効なプロジェクト名です。英字で始まり、英数字・ハイフン・アンダースコアのみ使用できます。"
        fi
    done

    # 既存ディレクトリチェック
    if [[ -d "$PROJECT_NAME" ]]; then
        print_error "ディレクトリ '$PROJECT_NAME' は既に存在します。"
        exit 1
    fi

    # --------------------------------------------------
    # 2. Pythonバージョンの入力
    # --------------------------------------------------
    print_step "利用可能な最新Pythonバージョンを確認中..."
    DEFAULT_PYTHON_VERSION=$(get_latest_python_version)
    print_success "最新バージョン: $DEFAULT_PYTHON_VERSION"

    while true; do
        echo -ne "${CYAN}🔢 Pythonバージョン [${DEFAULT_PYTHON_VERSION}]: ${NC}"
        read -r PYTHON_VERSION
        PYTHON_VERSION="${PYTHON_VERSION:-$DEFAULT_PYTHON_VERSION}"
        if validate_version "$PYTHON_VERSION"; then
            break
        else
            print_error "無効なバージョン形式です。例: 3.13, 3.14.2"
        fi
    done

    # --------------------------------------------------
    # 3. プロジェクトタイプの選択
    # --------------------------------------------------
    echo -e "${CYAN}📁 プロジェクトタイプを選択:${NC}"
    echo "  1) app - アプリケーション"
    echo "  2) lib - ライブラリ"
    while true; do
        echo -ne "${CYAN}選択 [1]: ${NC}"
        read -r PROJECT_TYPE_CHOICE
        PROJECT_TYPE_CHOICE="${PROJECT_TYPE_CHOICE:-1}"
        case "$PROJECT_TYPE_CHOICE" in
            1|app)
                PROJECT_TYPE="app"
                break
                ;;
            2|lib)
                PROJECT_TYPE="lib"
                break
                ;;
            *)
                print_error "1 または 2 を入力してください。"
                ;;
        esac
    done

    # --------------------------------------------------
    # 4. 開発ツールの確認
    # --------------------------------------------------
    echo -ne "${CYAN}🛠️  開発ツール (ruff, mypy, pytest) をインストール [Y/n]: ${NC}"
    read -r INSTALL_DEV_TOOLS
    INSTALL_DEV_TOOLS="${INSTALL_DEV_TOOLS:-Y}"

    # --------------------------------------------------
    # 確認表示
    # --------------------------------------------------
    echo ""
    echo "=================================================="
    echo -e "${YELLOW}設定内容:${NC}"
    echo "  プロジェクト名: $PROJECT_NAME"
    echo "  Pythonバージョン: $PYTHON_VERSION"
    echo "  プロジェクトタイプ: $PROJECT_TYPE"
    echo "  開発ツール: $([[ "$INSTALL_DEV_TOOLS" =~ ^[Yy]$ ]] && echo "インストールする" || echo "インストールしない")"
    echo "=================================================="
    echo ""

    # --------------------------------------------------
    # セットアップ開始
    # --------------------------------------------------
    echo -e "${GREEN}✨ セットアップを開始します...${NC}\n"

    # 1. ディレクトリ作成
    print_step "ディレクトリを作成中..."
    mkdir -p "$PROJECT_NAME"
    cd "$PROJECT_NAME"
    print_success "ディレクトリ '$PROJECT_NAME' を作成しました"

    # 2. Pythonインストール
    print_step "Python $PYTHON_VERSION をインストール中..."
    uv python install "$PYTHON_VERSION"
    print_success "Python $PYTHON_VERSION をインストールしました"

    # 3. プロジェクト初期化
    print_step "プロジェクトを初期化中..."
    uv init --name "$PROJECT_NAME" --python "$PYTHON_VERSION" --"$PROJECT_TYPE"
    print_success "プロジェクトを初期化しました"

    # 4. 開発ツールのインストール
    if [[ "$INSTALL_DEV_TOOLS" =~ ^[Yy]$ ]]; then
        print_step "開発ツールをインストール中..."
        uv add --dev ruff mypy pytest
        print_success "開発ツールをインストールしました"
    fi

    # 5. 依存関係の同期
    print_step "依存関係を同期中..."
    uv sync
    print_success "依存関係を同期しました"

    # 6. .gitignore生成
    print_step ".gitignore を生成中..."
    generate_gitignore > .gitignore
    print_success ".gitignore を生成しました"

    # 7. pyproject.tomlにツール設定を追記
    if [[ "$INSTALL_DEV_TOOLS" =~ ^[Yy]$ ]]; then
        print_step "pyproject.toml にツール設定を追記中..."
        local py_version
        local major_minor
        py_version=$(get_py_version "$PYTHON_VERSION")
        major_minor=$(get_major_minor "$PYTHON_VERSION")
        append_tool_config "pyproject.toml" "$py_version" "$major_minor"
        print_success "ツール設定を追記しました"
    fi

    # 8. testsディレクトリ作成
    if [[ "$INSTALL_DEV_TOOLS" =~ ^[Yy]$ ]]; then
        print_step "tests ディレクトリを作成中..."
        mkdir -p tests
        touch tests/__init__.py
        print_success "tests ディレクトリを作成しました"
    fi

    # 9. Git初期化
    print_step "Git リポジトリを初期化中..."
    git init --quiet
    print_success "Git リポジトリを初期化しました"

    # --------------------------------------------------
    # 完了メッセージ
    # --------------------------------------------------
    echo ""
    echo "=================================================="
    echo -e "${GREEN}🎉 セットアップが完了しました！${NC}"
    echo "=================================================="
    echo ""
    echo "次のステップ:"
    echo "  cd $PROJECT_NAME"
    echo "  source .venv/bin/activate  # または: uv run python"
    echo ""
    echo "便利なコマンド:"
    echo "  uv add <package>      # パッケージを追加"
    echo "  uv run python         # 仮想環境でPythonを実行"
    echo "  uv run pytest         # テストを実行"
    echo "  uv run ruff check .   # リントを実行"
    echo "  uv run mypy .         # 型チェックを実行"
    echo ""
}

# スクリプト実行
main "$@"
