# Claude Code 詳細セットアップガイド

このガイドでは、Claude Codeの環境構築と活用方法を段階的に説明します。

## 目次

1. [前提条件](#前提条件)
2. [インストール](#インストール)
3. [Phase 1: 基礎固め](#phase-1-基礎固め)
4. [Phase 2: カスタマイズ](#phase-2-カスタマイズ)
5. [Phase 3: 高度な活用](#phase-3-高度な活用)
6. [トラブルシューティング](#トラブルシューティング)

---

## 前提条件

### 必須

- **macOS**: 10.15 (Catalina) 以降
- **Node.js**: v18 以上
- **Anthropic契約**: Pro ($20/月) または Max ($100/月)

### 確認方法

```bash
# macOSバージョン確認
sw_vers

# Node.jsバージョン確認
node -v

# npmバージョン確認
npm -v
```

### Node.jsがない場合

```bash
# Homebrewでインストール
brew install node

# または nvm を使用（推奨）
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.zshrc  # または ~/.bashrc
nvm install 20
nvm use 20
```

---

## インストール

### Step 1: Claude Codeをインストール

```bash
npm install -g @anthropic-ai/claude-code
```

### Step 2: 認証

```bash
# Claude Codeを起動して認証
claude

# ブラウザが開くのでAnthropicアカウントでログイン
```

### Step 3: 確認

```bash
# バージョン確認
claude --version

# ヘルプ表示
claude --help
```

---

## Phase 1: 基礎固め

### 1.1 CLAUDE.mdの生成

プロジェクトディレクトリで:

```bash
cd your-project
claude
```

Claude Code内で:
```
/init
```

これにより、プロジェクトに最適化された `CLAUDE.md` が生成されます。

### 1.2 基本的な使い方

```
# 質問する
このプロジェクトの構造を説明して

# ファイルを編集
README.mdに使い方セクションを追加して

# コードを生成
ユーザー認証機能を実装して
```

### 1.3 並列実行を試す

```
# 複数の視点で分析
5人の専門家視点で、このアーキテクチャを評価して：
- セキュリティ専門家
- パフォーマンス専門家
- UX専門家
- スケーラビリティ専門家
- コスト最適化専門家

# 並列タスク
4つの並列タスクで以下を同時に実行して：
- タスク1: ユニットテストを作成
- タスク2: ドキュメントを更新
- タスク3: 型定義を追加
- タスク4: リファクタリング提案
```

---

## Phase 2: カスタマイズ

### 2.1 カスタムコマンドの作成

```bash
# プロジェクト固有のコマンド
mkdir -p .claude/commands

# コマンドファイルを作成
cat > .claude/commands/deploy-check.md << 'EOF'
# デプロイ前チェック

以下の項目を確認して：

1. すべてのテストがパス
2. TypeScriptエラーなし
3. 未コミットの変更なし
4. 依存関係の脆弱性なし

問題があれば詳細と解決策を提示。
EOF
```

使用方法:
```
/project:deploy-check
```

### 2.2 グローバルコマンドの作成

```bash
# すべてのプロジェクトで使えるコマンド
mkdir -p ~/.claude/commands

cat > ~/.claude/commands/morning-standup.md << 'EOF'
# 朝のスタンドアップ

以下を確認して報告：

1. 昨日の変更点（git log）
2. 未完了のTODO（コード内）
3. 失敗しているテスト
4. 今日の優先タスク提案
EOF
```

使用方法:
```
/user:morning-standup
```

### 2.3 CLAUDE.mdのカスタマイズ

```bash
# テンプレートをコピー
cp templates/CLAUDE.md ./CLAUDE.md

# エディタで編集
# プロジェクト固有の情報を追加
```

重要なポイント:
- **簡潔に保つ**: 150-200行以内
- **具体的に**: 抽象的な指示より具体例
- **更新する**: プロジェクトの変化に合わせて

---

## Phase 3: 高度な活用

### 3.1 カスタムサブエージェントの作成

```bash
mkdir -p .claude/agents

cat > .claude/agents/security-auditor.md << 'EOF'
---
name: security-auditor
description: セキュリティ脆弱性を検出する監査エージェント
model: sonnet
tools: Read, Grep, Glob
---

# Security Auditor

セキュリティ監査を行うエージェント。

## 検査項目

1. OWASP Top 10
2. 認証・認可の実装
3. 機密情報の取り扱い
4. 入力バリデーション

## 出力形式

| 深刻度 | カテゴリ | ファイル:行 | 問題 | 修正案 |
EOF
```

### 3.2 Memory MCPの導入（オプション）

```bash
# .mcp.json を作成
cat > .mcp.json << 'EOF'
{
  "mcpServers": {
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"]
    }
  }
}
EOF
```

これにより、セッション間で記憶を保持できます。

### 3.3 Hooksの設定（オプション）

`.claude/settings.json`:

```json
{
  "hooks": {
    "preFileEdit": {
      "command": "prettier --check"
    },
    "postCommit": {
      "command": "npm test"
    }
  }
}
```

---

## Phase 4: Commander環境のセットアップ（上級者向け）

### 4.1 Commander体験とは

「ダッシュボードを眺めて、たまに話しかけるだけ」でタスクが自動的に進む体験です。

**アーキテクチャ**:
```
Commander（大臣+幹部）
  ↓ タスク分解・委譲
サブエージェント群（係員たち）
  → architect, implementer, tester, reviewer, debugger
```

**詳細**: [Commanderガイド](./commander-guide.md) を参照

### 4.2 プラグインのインストール

```bash
# マーケットプレースを追加
claude plugin marketplace add wshobson/agents
claude plugin marketplace add affaan-m/everything-claude-code

# 必須プラグインをインストール
claude plugin install code-documentation@claude-code-workflows
claude plugin install debugging-toolkit@claude-code-workflows
claude plugin install business-analytics@claude-code-workflows
claude plugin install plugin-dev@claude-plugins-official

# 確認
claude plugin list
```

**重要**: コマンド構文に注意
- ❌ `/plugin marketplace add`
- ✅ `claude plugin marketplace add`

### 4.3 ディレクトリ構造の作成

```bash
# プロジェクト固有ディレクトリ
mkdir -p .claude/{agents,skills,docs}
mkdir -p context

# グローバルディレクトリ
mkdir -p ~/.claude/{agents,memory}
```

### 4.4 必須ファイルの作成

**グローバル設定**:

1. `~/.claude/agents/expert-panel.md` - メタ認知用専門家パネル
2. `~/.claude/memory/preferences.md` - ユーザーの好み

**プロジェクト設定**:

1. `CLAUDE.md` - Commander（大臣+幹部）の定義
2. `dashboard.md` - 状況報告ダッシュボード
3. `progress.md` - 全サブエージェント共有ログ
4. `.claude/agents/*.md` - サブエージェント定義
   - architect.md（設計）
   - implementer.md（実装）
   - tester.md（テスト）
   - debugger.md（デバッグ）
   - security.md（セキュリティ）

**テンプレート**: このリポジトリの `.claude/` および `templates/` を参照

### 4.5 セットアップ方法

**オプション1: 自動セットアップ**

```bash
# このリポジトリをクローン
git clone https://github.com/naosugi/claude-code-setup.git
cd claude-code-setup

# Commander環境をセットアップ
./setup.sh --commander
```

**オプション2: 手動セットアップ**

```bash
# プロジェクトで Claude Code を起動
cd your-project
claude

# Claude Code内で指示
```

```
このプロジェクトにCommander環境をセットアップして。

必要なファイル:
- CLAUDE.md（Commander定義）
- dashboard.md（状況報告）
- progress.md（作業ログ）
- .claude/agents/*.md（サブエージェント）

参照: https://github.com/naosugi/claude-code-setup の .claude/ と templates/
```

### 4.6 動作確認

```bash
# 新しいセッションを開始（CLAUDE.mdを反映）
exit  # または Ctrl+C
claude

# 簡単なタスクで確認
```

Claude Code内で:
```
簡単なREADME.mdを作成して
```

**確認ポイント**:
- [ ] Commander がタスク分解を提示する
- [ ] 人間に承認を求める
- [ ] dashboard.md が更新される
- [ ] progress.md にログが追記される

**dashboard.mdの確認**:

エディタで `dashboard.md` を開き、Markdownプレビュー（Cmd+Shift+V）で表示。
リアルタイムで更新されることを確認。

### 4.7 使い方の基本

```
1. やりたいことを伝える
   > ユーザー認証機能を実装して

2. タスク分解を承認
   [Commander] この分解で進めてよいですか？
   > いいよ

3. dashboard.md を眺める
   [あなたはコーヒーを飲みながら進捗を確認]

4. 判断が必要な時だけ話しかける
   [Commander] JWT vs OAuth、どちらを採用しますか？
   > JWTで
```

### 4.8 詳細ガイド

- [Commanderガイド](./commander-guide.md) - 詳細な使い方

---

## トラブルシューティング

### Q: Claude Codeが起動しない

```bash
# キャッシュをクリア
rm -rf ~/.claude/cache

# 再インストール
npm uninstall -g @anthropic-ai/claude-code
npm install -g @anthropic-ai/claude-code
```

### Q: 認証エラーが出る

```bash
# 認証をリセット
claude auth logout
claude auth login
```

### Q: コマンドが認識されない

- ファイル名が `.md` で終わっているか確認
- ファイルの配置場所を確認:
  - プロジェクト固有: `.claude/commands/`
  - グローバル: `~/.claude/commands/`

### Q: 並列実行でコストが急増

- 並列数を減らす（3-4程度が目安）
- Claude Maxプランを検討
- 不要なエージェントを減らす

### Q: AIが指示を忘れる

- CLAUDE.mdに重要事項を記載
- 長いセッションは分割
- 明示的に「先ほどの指示を確認して」と伝える

---

## 参考リンク

- [Claude Code公式ドキュメント](https://docs.anthropic.com/en/docs/claude-code)
- [ベストプラクティス](https://www.anthropic.com/engineering/claude-code-best-practices)
- [Awesome Claude Code](https://github.com/jqueryscript/awesome-claude-code)

---

## 次のステップ

1. **今日**: `/init` でCLAUDE.mdを生成、並列実行を試す
2. **今週**: カスタムコマンドを3つ作成
3. **今月**: カスタムエージェントを作成、チームに展開
