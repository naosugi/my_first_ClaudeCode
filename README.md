# Claude Code 環境構築キット for Mac

非技術者でも「楽に」「安定的に」Claude Codeをカスタマイズするための環境構築キットです。

> **初めての方へ**: まず [はじめてのClaude Code](docs/getting-started.md) をお読みください（10分で読めます）

## 概要

このリポジトリは、Claude Codeの公式機能を活用して、効率的なAIワークフローを構築するためのテンプレートとスクリプトを提供します。

### 含まれるもの

```
.
├── setup.sh                    # Mac用セットアップスクリプト
├── templates/
│   └── CLAUDE.md              # CLAUDE.mdテンプレート
├── .claude/
│   ├── commands/              # サンプルカスタムコマンド
│   │   ├── research.md        # 並列リサーチコマンド
│   │   ├── review.md          # コードレビューコマンド
│   │   └── summarize.md       # ドキュメント要約コマンド
│   └── agents/                # サンプルサブエージェント
│       ├── researcher.md      # リサーチャーエージェント
│       ├── reviewer.md        # レビュアーエージェント
│       └── analyst.md         # アナリストエージェント
└── docs/
    ├── getting-started.md     # 初心者向け入門ガイド（まずこれを読む）
    ├── setup-guide.md         # 詳細セットアップガイド
    ├── commander-guide.md        # 自動化体験ガイド（上級者向け）
    └── troubleshooting.md     # トラブルシューティング事例集
```

## クイックスタート

### 前提条件

- macOS
- Anthropic APIキー または Claude Pro/Max契約
- Node.js 18以上

### セットアップ

```bash
# 1. このリポジトリをクローン
git clone https://github.com/naosugi/claude-code-setup.git
cd claude-code-setup

# 2. セットアップスクリプトを実行
chmod +x setup.sh
./setup.sh
```

## 使い方

### Phase 1: 基礎固め（今日からできること）

#### 1. Claude Codeを起動
```bash
claude
```

#### 2. CLAUDE.mdを生成
```
/init
```

#### 3. 並列実行を試す
```
5人の専門家視点で、このビジネスアイデアを評価して：$YOUR_IDEA
```

### Phase 2: カスタムコマンドを使う

```bash
# リサーチコマンド
/project:research AI業界の最新動向

# コードレビュー
/project:review

# ドキュメント要約
/project:summarize README.md
```

### Phase 3: サブエージェントを活用

```
# リサーチャーを呼び出し
市場調査をresearcherエージェントに依頼して

# 並列で複数エージェント
reviewer, analyst, researcher の3エージェントで並列にこの提案を評価して
```

### Phase 4: Commander環境（上級者向け）

「ダッシュボードを眺めて、たまに話しかけるだけ」の自動化体験

```
あなた: 認証機能を実装して

Commander: タスクを分解しました...この分解で進めてよいですか？

あなた: いいよ

[dashboard.md を眺めながら待つ]

Commander: 全タスク完了。問題ありません。
```

**仕組み**:
- Commander（大臣+幹部）が自動的にタスク分解・委譲
- サブエージェント群（係員）が並列実行
- dashboard.md でリアルタイム進捗確認
- 重要な判断は専門家パネルで熟議

**詳細**: [Commanderガイド](docs/commander-guide.md) を参照

## 4層アーキテクチャ

```
Layer 4: ワークフロー自動化
├── カスタムコマンド (.claude/commands/)
├── Hooks（自動実行アクション）
└── MCP連携（外部サービス統合）

Layer 3: プラグインエコシステム
├── 公式プラグイン
├── コミュニティプラグイン
└── 自作プラグイン

Layer 2: 並列実行・エージェント管理
├── Task Tool（公式サブエージェント機能）
├── カスタムサブエージェント (.claude/agents/)
└── ビルトインエージェント（Explore, Plan, Task）

Layer 1: 基盤設定
├── CLAUDE.md（プロジェクト固有の知識）
├── settings.json（権限・セキュリティ）
└── Memory MCP（セッション間記憶）
```

## カスタマイズ

### CLAUDE.mdのカスタマイズ

`templates/CLAUDE.md` をプロジェクトルートにコピーして編集：

```bash
cp templates/CLAUDE.md ./CLAUDE.md
```

### カスタムコマンドの追加

`.claude/commands/` にMarkdownファイルを追加：

```markdown
# .claude/commands/my-command.md
あなたの指示をここに書く：$ARGUMENTS
```

使用: `/project:my-command 引数`

### カスタムエージェントの追加

`.claude/agents/` にMarkdownファイルを追加：

```markdown
---
name: my-agent
description: エージェントの説明
model: sonnet
tools: Read, Grep, Glob
---

# My Agent

エージェントの振る舞いをここに定義
```

## 参考リンク

- [Claude Code公式ドキュメント](https://docs.anthropic.com/en/docs/claude-code)
- [Claude Code ベストプラクティス](https://www.anthropic.com/engineering/claude-code-best-practices)
- [Awesome Claude Code](https://github.com/jqueryscript/awesome-claude-code)

## ライセンス

MIT
