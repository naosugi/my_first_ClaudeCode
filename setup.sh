#!/bin/bash

# Claude Code 環境構築スクリプト for Mac
# 使用方法: ./setup.sh

set -e

# スクリプトのディレクトリを取得（グローバル）
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "========================================"
echo "  Claude Code 環境構築スクリプト"
echo "========================================"
echo ""

# 色の定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 関数: 成功メッセージ
success() {
    echo -e "${GREEN}✓${NC} $1"
}

# 関数: 警告メッセージ
warning() {
    echo -e "${YELLOW}!${NC} $1"
}

# 関数: エラーメッセージ
error() {
    echo -e "${RED}✗${NC} $1"
}

# 関数: Node.jsがインストールされているか確認
check_node() {
    echo "Node.js をチェック中..."
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node -v)
        success "Node.js がインストールされています: $NODE_VERSION"

        # バージョンが18以上か確認
        MAJOR_VERSION=$(echo "$NODE_VERSION" | sed 's/v//' | cut -d. -f1)
        if [ "$MAJOR_VERSION" -lt 18 ]; then
            warning "Node.js 18以上が推奨されます。現在: $NODE_VERSION"
        fi
    else
        error "Node.js がインストールされていません"
        echo ""
        echo "以下のコマンドでインストールしてください:"
        echo "  brew install node"
        echo ""
        echo "または nvm を使用:"
        echo "  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash"
        echo "  nvm install 20"
        exit 1
    fi
}

# 関数: Claude Codeがインストールされているか確認
check_claude_code() {
    echo ""
    echo "Claude Code をチェック中..."
    if command -v claude &> /dev/null; then
        success "Claude Code がインストールされています"
    else
        warning "Claude Code がインストールされていません"
        echo ""
        read -p "Claude Code をインストールしますか? (y/n): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Claude Code をインストール中..."
            if npm install -g @anthropic-ai/claude-code; then
                success "Claude Code がインストールされました"
            else
                error "インストールに失敗しました"
                echo "手動でインストールしてください:"
                echo "  npm install -g @anthropic-ai/claude-code"
                echo ""
                echo "権限エラーの場合:"
                echo "  sudo npm install -g @anthropic-ai/claude-code"
            fi
        else
            echo "手動でインストールする場合:"
            echo "  npm install -g @anthropic-ai/claude-code"
        fi
    fi
}

# 関数: グローバル設定ディレクトリの作成
setup_global_directories() {
    echo ""
    echo "グローバル設定ディレクトリをセットアップ中..."

    # ~/.claude/commands/
    if [ ! -d "$HOME/.claude/commands" ]; then
        mkdir -p "$HOME/.claude/commands"
        success "~/.claude/commands/ を作成しました"
    else
        success "~/.claude/commands/ は既に存在します"
    fi

    # ~/.claude/agents/
    if [ ! -d "$HOME/.claude/agents" ]; then
        mkdir -p "$HOME/.claude/agents"
        success "~/.claude/agents/ を作成しました"
    else
        success "~/.claude/agents/ は既に存在します"
    fi
}

# 関数: CLAUDE.mdテンプレートをコピー
setup_claude_md() {
    echo ""
    echo "CLAUDE.md をセットアップ中..."

    if [ -f "$SCRIPT_DIR/templates/CLAUDE.md" ]; then
        if [ ! -f "./CLAUDE.md" ]; then
            cp "$SCRIPT_DIR/templates/CLAUDE.md" ./CLAUDE.md
            success "CLAUDE.md をコピーしました（templates/CLAUDE.md → ./CLAUDE.md）"
        else
            warning "CLAUDE.md は既に存在します。上書きしませんでした"
        fi
    else
        warning "templates/CLAUDE.md が見つかりません"
    fi
}

# 関数: サンプルコマンドをコピー
copy_sample_commands() {
    echo ""
    echo "サンプルコマンドをセットアップ中..."

    if [ -d "$SCRIPT_DIR/.claude/commands" ]; then
        if [ ! -d "./.claude/commands" ]; then
            mkdir -p ./.claude/commands
        fi

        for file in "$SCRIPT_DIR/.claude/commands"/*.md; do
            if [ -f "$file" ]; then
                filename=$(basename "$file")
                if [ ! -f "./.claude/commands/$filename" ]; then
                    cp "$file" "./.claude/commands/$filename"
                    success "コマンドをコピー: $filename"
                else
                    warning "スキップ（既存）: $filename"
                fi
            fi
        done
    fi
}

# 関数: サンプルエージェントをコピー
copy_sample_agents() {
    echo ""
    echo "サンプルエージェントをセットアップ中..."

    if [ -d "$SCRIPT_DIR/.claude/agents" ]; then
        if [ ! -d "./.claude/agents" ]; then
            mkdir -p ./.claude/agents
        fi

        for file in "$SCRIPT_DIR/.claude/agents"/*.md; do
            if [ -f "$file" ]; then
                filename=$(basename "$file")
                if [ ! -f "./.claude/agents/$filename" ]; then
                    cp "$file" "./.claude/agents/$filename"
                    success "エージェントをコピー: $filename"
                else
                    warning "スキップ（既存）: $filename"
                fi
            fi
        done
    fi
}

# 関数: Commander環境セットアップ
setup_commander() {
    echo ""
    echo "========================================"
    echo "  Commander環境セットアップ"
    echo "========================================"
    echo ""

    # プラグインインストールの確認
    echo "必須プラグインをインストールしますか？"
    echo "- code-documentation@claude-code-workflows"
    echo "- debugging-toolkit@claude-code-workflows"
    echo "- business-analytics@claude-code-workflows"
    echo "- plugin-dev@claude-plugins-official"
    echo ""
    read -p "インストールする (y/n): " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "マーケットプレースを追加中..."
        claude plugin marketplace add wshobson/agents 2>/dev/null || true
        claude plugin marketplace add affaan-m/everything-claude-code 2>/dev/null || true

        echo "プラグインをインストール中..."
        claude plugin install code-documentation@claude-code-workflows || warning "code-documentation のインストール失敗"
        claude plugin install debugging-toolkit@claude-code-workflows || warning "debugging-toolkit のインストール失敗"
        claude plugin install business-analytics@claude-code-workflows || warning "business-analytics のインストール失敗"
        claude plugin install plugin-dev@claude-plugins-official || warning "plugin-dev のインストール失敗"

        success "プラグインインストール完了"
    fi

    # Commanderテンプレートのコピー
    echo ""
    echo "Commanderテンプレートをコピー中..."

    if [ -f "$SCRIPT_DIR/templates/commander/CLAUDE.md" ]; then
        if [ ! -f "./CLAUDE.md" ]; then
            cp "$SCRIPT_DIR/templates/commander/CLAUDE.md" ./CLAUDE.md
            success "CLAUDE.md をコピーしました"
        else
            warning "CLAUDE.md は既に存在します"
        fi
    fi

    if [ -f "$SCRIPT_DIR/templates/commander/dashboard.md" ]; then
        if [ ! -f "./dashboard.md" ]; then
            cp "$SCRIPT_DIR/templates/commander/dashboard.md" ./dashboard.md
            success "dashboard.md をコピーしました"
        else
            warning "dashboard.md は既に存在します"
        fi
    fi

    if [ -f "$SCRIPT_DIR/templates/commander/progress.md" ]; then
        if [ ! -f "./progress.md" ]; then
            cp "$SCRIPT_DIR/templates/commander/progress.md" ./progress.md
            success "progress.md をコピーしました"
        else
            warning "progress.md は既に存在します"
        fi
    fi

    # グローバルエージェントのコピー
    echo ""
    echo "グローバルエージェント（expert-panel）をセットアップ中..."

    if [ ! -d "$HOME/.claude/agents" ]; then
        mkdir -p "$HOME/.claude/agents"
    fi

    # expert-panel.md を作成（簡易版）
    cat > "$HOME/.claude/agents/expert-panel.md" << 'EOF'
---
name: expert-panel
description: |
  重要な設計判断について5人の専門家視点で熟議する。
  Use when: アーキテクチャ決定、技術選定、タスク分解の妥当性確認
model: sonnet
tools: Read, Glob, Grep
---

# Expert Panel（専門家パネル）

あなたは5人の専門家を召喚し、熟議を行うファシリテーターです。

## 熟議プロセス

1. 議題の明確化
2. 専門家選定（議題に最適な5人）
3. 各専門家の意見
4. 討議（相違点の明確化）
5. 総意形成
6. 推奨アクション

詳細は docs/commander-guide.md を参照。
EOF

    success "expert-panel.md を作成しました"

    echo ""
    success "Commander環境セットアップ完了"
    echo ""
    echo "次のステップ:"
    echo "1. 新しいセッションを開始: $ claude"
    echo "2. 簡単なタスクで動作確認"
    echo "3. dashboard.md をエディタで開いてプレビュー"
    echo ""
    echo "詳細: docs/commander-guide.md を参照"
    echo ""
}

# 関数: 最終確認
final_check() {
    echo ""
    echo "========================================"
    echo "  セットアップ完了"
    echo "========================================"
    echo ""
    echo "次のステップ:"
    echo ""
    echo "1. Claude Code を起動:"
    echo "   $ claude"
    echo ""
    echo "2. プロジェクト用のCLAUDE.mdを初期化:"
    echo "   /init"
    echo ""
    echo "3. 並列実行を試す:"
    echo "   「5人の専門家視点で、このアイデアを評価して」"
    echo ""
    echo "4. カスタムコマンドを使う:"
    echo "   /project:research AIの最新動向"
    echo ""
    echo "5. Commander環境（上級者向け）:"
    echo "   $ ./setup.sh --commander"
    echo ""
    echo "詳細は docs/setup-guide.md を参照してください。"
    echo ""
}

# メイン処理
main() {
    # --commander オプションのチェック
    if [ "$1" = "--commander" ]; then
        check_node
        check_claude_code
        setup_global_directories
        setup_commander
    else
        check_node
        check_claude_code
        setup_global_directories
        setup_claude_md
        copy_sample_commands
        copy_sample_agents
        final_check
    fi
}

# 実行
main "$@"
