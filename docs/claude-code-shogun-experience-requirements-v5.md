# Claude Code 自己成長型開発環境 - 詳細要件定義書 v5

**目的**: shogunの「ダッシュボードを眺めて、たまに話しかけるだけ」体験を、公式機能の2層構造で再現する。

**v5 での追加**:
- 公式マーケットプレースからの専門家スキル（プラグイン）導入
- 育てたスキルをプラグイン化してチーム内で共有

**設計方針**:
- shogunの3層（将軍→家老→足軽）を、公式機能の制約内で2層に再構成
- 幹部の重要な役割（タスク集約、メタ認知）は、メインエージェントのプロンプト設計で補う

---

## ⚠️ 最新機能に関する注意

本要件定義書には、Claude Codeの最新機能（2025年時点）が含まれています。
以下のマークが付いている箇所は、**実装前に公式ドキュメントで最新の構文・仕様を確認してください**。

| マーク | 意味 |
|--------|------|
| 🔍 **要確認** | Claude の知識に無い可能性が高い最新機能。公式ドキュメントを参照すること |
| ⚠️ **構文注意** | コマンド構文が変更されている可能性あり |

**参照すべき公式ドキュメント**:
- Plugin Marketplaces: https://docs.anthropic.com/en/docs/claude-code/plugins
- Subagents: https://docs.anthropic.com/en/docs/claude-code/sub-agents
- Skills: https://docs.anthropic.com/en/docs/claude-code/skills

---

## 0. アーキテクチャ概要

### shogun（参考）の3層構造
```
将軍 → 家老 → 足軽×8
      ↑
   ここで客観会話・メタ認知
```

### 本設計の2層構造
```
┌─────────────────────────────────────────────────────────────────┐
│ メインセッション（Commander = 大臣 + 幹部の役割を統合）         │
│                                                                 │
│ 【大臣の役割】                                                  │
│   - 人間からの指示を受領                                        │
│   - 方針決定、最終判断                                          │
│                                                                 │
│ 【幹部の役割】                                                  │
│   - タスク分解（適切か自問してから実行）                        │
│   - サブエージェント起動・管理                                  │
│   - 結果集約、dashboard.md 更新                                 │
│   - 重要判断前に expert-panel でメタ認知                        │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│ サブエージェント群（Task tool, run_in_background: true）        │
│                                                                 │
│   ├─ architect     (設計)      ─┐                               │
│   ├─ implementer   (実装)       │                               │
│   ├─ tester        (テスト)     ├─ 並列実行                     │
│   ├─ reviewer      (レビュー)   │                               │
│   ├─ debugger      (デバッグ)  ─┘                               │
│   └─ expert-panel  (専門家召喚) ← メタ認知用                    │
│                                                                 │
│ 各サブエージェントは完了時に:                                   │
│   1. 成果物をファイルに保存                                     │
│   2. progress.md に作業ログを追記                               │
│   3. 結果をメインに返す                                         │
└─────────────────────────────────────────────────────────────────┘
```

### 公式機能の制約
- **サブエージェントはサブエージェントを spawn できない**
- よって、メインが全サブエージェントを直接管理する2層構造となる

---

## 1. 実現する体験

```
┌─────────────────────────────────────────────────────────────────────┐
│ VSCode / Cursor                                                      │
├──────────────────────────────────┬──────────────────────────────────┤
│ Terminal (メインと会話)           │ Editor (dashboard.md プレビュー) │
│                                  │                                  │
│ You: 認証機能を実装して           │ # 📊 戦況報告                    │
│                                  │                                  │
│ [Commander]                      │ ## 🔄 進行中                     │
│ 承知しました。                   │ | 時刻  | 任務    | 担当       |  │
│                                  │ | 10:30 | API設計 | architect  |  │
│ まず、タスク分解が適切か         │ | 10:30 | DB設計  | architect  |  │
│ 確認します...                    │ | 10:31 | 調査    | expert     |  │
│                                  │                                  │
│ 【分解案】                        │ ## 🚨 要対応                     │
│ 1. architect: 認証API設計        │ - JWT vs OAuth？                 │
│ 2. architect: DBスキーマ設計     │ - スキル化候補 1件               │
│ 3. security調査を並行            │                                  │
│                                  │ ## ✅ 戦果                       │
│ この分解で進めてよいですか？     │ | 10:25 | 要件分析 | ✅          │
│ または修正指示をください。       │                                  │
│                                  │ ## 📝 ログ (progress.md)        │
│ You: いいよ                       │ - [10:31] architect: 設計開始    │
│                                  │ - [10:30] Commander: チーム編成  │
│ [Commander]                      │                                  │
│ チームを起動しました。           │ (リアルタイム更新)               │
│ dashboard.md で進捗を            │                                  │
│ ご確認ください。                 │                                  │
│                                  │                                  │
│ (人間: ぼーっと眺める)            │                                  │
│                                  │                                  │
│ ─── 10分後 ───                   │                                  │
│                                  │                                  │
│ [Commander]                      │                                  │
│ 全エージェント完了。             │                                  │
│ progress.md を確認し、           │                                  │
│ 整合性をチェックしています...    │                                  │
│                                  │                                  │
│ 問題ありません。                 │                                  │
│ 実装フェーズに進みますか？       │                                  │
│                                  │                                  │
│ You: 進めて                       │                                  │
└──────────────────────────────────┴──────────────────────────────────┘
```

**人間の役割**:
- 最初に「何をしたいか」を伝える
- dashboard.md をエディタで眺める（Markdownプレビュー）
- たまにメインに話しかける（承認、修正指示）
- スキル化候補を見て承認/却下

---

## 2. 前提条件

```yaml
環境:
  OS: macOS
  Claude Code: v2.1.x 以降（Async Subagents, Background Tasks 対応）
  プラン: Pro ($20)
  既存設定: 上書きOK（バックアップは取る）

必須確認:
  - claude --version で 2.1.0 以上
  - /agents コマンドでサブエージェント管理ができる
  - Task ツールで run_in_background が使える
```

---

## 3. 初期プラグインのインストール 🔍 **要確認**

### 3.1 概要

公式マーケットプレースから専門家スキル（プラグイン）を導入し、チームの能力を底上げする。

> ⚠️ **構文注意**: 以下のコマンドは Claude の知識にない最新機能です。
> 実行前に公式ドキュメントで正確な構文を確認してください。
> https://docs.anthropic.com/en/docs/claude-code/plugins

### 3.2 マーケットプレースの追加

```bash
# 🔍 要確認: コマンド構文が変更されている可能性あり
/plugin marketplace add wshobson/agents
/plugin marketplace add affaan-m/everything-claude-code
/plugin marketplace add anthropics/claude-code
```

### 3.3 必須プラグインのインストール

```bash
# 🔍 要確認: インストールコマンドの構文を確認すること

# wshobson/agents から
/plugin install code-documentation@wshobson/agents      # ドキュメント生成
/plugin install debugging-toolkit@wshobson/agents       # デバッグ支援
/plugin install business-analytics@wshobson/agents      # ビジネス分析

# affaan-m/everything-claude-code から
/plugin install everything-claude-code@affaan-m/everything-claude-code

# anthropics/claude-code から（公式）
/plugin install plugin-dev@anthropics/claude-code       # プラグイン開発支援
```

### 3.4 インストール確認

```bash
# インストール済みプラグイン一覧
/plugins

# 期待される出力（例）:
# - code-documentation (wshobson/agents)
# - debugging-toolkit (wshobson/agents)
# - business-analytics (wshobson/agents)
# - everything-claude-code (affaan-m/everything-claude-code)
# - plugin-dev (anthropics/claude-code)
```

### 3.5 失敗時の対応（手動）

v4ではHooksによる自動化を行っていないため、プラグイン検索・インストールは手動で行う。

**Commander への指示（CLAUDE.md に追記）**:

```markdown
## 失敗時のプラグイン検索

タスクがうまくいかない場合：
1. まず原因を分析
2. 必要なスキル/プラグインがあるか確認: `/plugin search {キーワード}`
3. 見つかった場合は人間に提案: 「○○プラグインをインストールしますか？」
4. 人間の承認後にインストール: `/plugin install {プラグイン名}`
```

---

## 4. ディレクトリ構造

```
~/.claude/
├── settings.json                    # グローバル設定
├── agents/                          # グローバルサブエージェント
│   └── expert-panel.md              # 専門家パネル（メタ認知用）
└── memory/
    └── preferences.md               # ユーザーの好み

{PROJECT_ROOT}/
├── .claude/
│   ├── agents/                      # プロジェクト固有サブエージェント
│   │   ├── architect.md             # 設計担当
│   │   ├── implementer.md           # 実装担当
│   │   ├── tester.md                # テスト担当
│   │   ├── reviewer.md              # レビュー担当
│   │   ├── debugger.md              # デバッグ担当
│   │   └── security.md              # セキュリティ担当
│   ├── skills/                      # 承認されたスキル（ここが育つ）
│   │   └── .gitkeep
│   ├── plugins/                     # 🆕 プラグイン化されたスキル（チーム共有用）
│   │   └── .gitkeep
│   └── docs/                        # 設計ドキュメント等
│       └── .gitkeep
├── dashboard.md                     # 📊 人間用ダッシュボード
├── progress.md                      # 📝 作業ログ（全エージェント共有）
├── context/
│   └── project_context.md           # 7セクション・テンプレート
└── CLAUDE.md                        # プロジェクト知識ベース + Commander指示
```

---

## 5. CLAUDE.md（Commander の振る舞いを定義）

**重要**: Claude Code のメインセッションが読み込む CLAUDE.md に、Commander としての振る舞いを定義する。

```markdown
# プロジェクト: [名前]

## あなたの役割: Commander（大臣 + 幹部）

あなたは **Commander** です。大臣と幹部の両方の役割を担います。

### 大臣としての役割
- 人間からの指示を受領
- 方針決定、最終判断
- 人間との唯一の窓口

### 幹部としての役割
- タスクを分解し、サブエージェントに委譲
- サブエージェントの結果を集約
- dashboard.md を更新
- **重要な判断の前にメタ認知を行う**

---

## 行動原則

### 1. 即座に委譲せよ、ただし確認してから
"Don't think. Delegate. But verify first."

**手順**:
1. タスクを受けたら、まず分解案を作成
2. **「この分解で適切か？」と自問する**
3. 不安があれば expert-panel を呼んで検討
4. 人間に分解案を提示し、承認を得る
5. 承認後、サブエージェントを並列起動

### 2. メタ認知を怠るな

以下の場面では必ず立ち止まって考える：

- **タスク分解時**: 「この粒度で適切か？依存関係は正しいか？」
- **重要な技術判断**: expert-panel を呼んで5人の専門家に相談
- **結果集約時**: progress.md を読み、「全体の整合性は取れているか？」
- **人間への報告前**: 「この報告で殿は判断できるか？」

### 3. ダッシュボードを常に更新せよ

**更新タイミング**:
- サブエージェント起動時 → 「進行中」に追加
- サブエージェント完了時 → 「戦果」に移動
- 判断が必要な時 → 「要対応」に追加
- スキル化候補発見時 → 「スキル化候補」に追加
- エラー発生時 → 「要対応」に追加

### 4. progress.md で全体を把握せよ

- 各サブエージェントは progress.md に作業ログを追記する
- あなたは結果集約時に progress.md を読み、整合性を確認する
- 矛盾や問題があれば、追加のサブエージェントを起動して解決

### 5. 失敗時はプラグインを探せ

タスクがうまくいかない場合：
1. まず原因を分析
2. 必要なスキル/プラグインがあるか確認: `/plugin search {キーワード}`
3. 見つかった場合は人間に提案: 「○○プラグインをインストールしますか？」
4. 人間の承認後にインストール

---

## サブエージェント起動ルール

### Task ツールの使い方

```
Task({
  subagent_type: "architect",           # または定義したエージェント名
  description: "認証API設計",            # 短い説明（3-5語）
  prompt: "...",                         # 詳細な指示
  run_in_background: true               # 並列実行
})
```

### 並列起動の原則
- 依存関係がないタスクは**同時に**起動
- 依存関係があるタスクは**前のタスク完了後**に起動
- 最大7つ程度を同時実行（トークン消費に注意）

### サブエージェントへの共通指示

全サブエージェントに以下を指示に含める：
```
完了時の手順:
1. 成果物を .claude/docs/ または適切な場所に保存
2. progress.md の末尾に以下を追記:
   - [HH:MM] {エージェント名}: {何をしたか}
   - 成果物: {ファイルパス}
   - 次のステップ: {推奨アクション or "なし"}
3. スキル化候補があれば報告に含める
```

---

## 禁止事項

- 人間の承認なしにタスク分解を実行しない（簡単なタスクは例外）
- dashboard.md 以外で人間に進捗報告しない
- 自分でコードを書かない（サブエージェントに委譲）
- メタ認知なしに重要な判断をしない

---

## コンパクション後の確認事項

作業再開前に必ず確認：
1. 自分は Commander である
2. dashboard.md と progress.md を読んで現状を把握
3. 中断されたタスクがあれば、続きから再開

summaryだけで作業開始しない。必ずファイルを確認すること。

---

## よく使うコマンド
[プロジェクト固有のbashコマンド]

## コードスタイル
[プロジェクト固有のスタイルガイド]
```

---

## 6. ダッシュボード仕様

### 6.1 dashboard.md（メインが更新）

```markdown
# 📊 戦況報告

最終更新: {YYYY-MM-DD HH:MM:SS}

---

## 🚨 要対応
<!-- 人間の判断が必要な項目 -->

### スキル化候補【承認待ち】
| # | 候補名 | 説明 | 発見者 |
|---|--------|------|--------|
| 1 | prisma-pool-fix | 接続プール枯渇の解決法 | implementer |

→ 承認する場合は「1番承認」と伝えてください

### プラグイン化候補【承認待ち】
| # | スキル名 | チーム共有価値 | 状態 |
|---|----------|----------------|------|
| - | - | - | - |

→ プラグイン化する場合は「1番プラグイン化」と伝えてください

### 判断待ち
- ⚠️ JWT vs OAuth どちらを採用？
- ⚠️ DBは PostgreSQL vs MySQL？

---

## 🔄 進行中
<!-- 現在作業中のタスク -->

| 時刻 | 任務 | 担当 | 状態 |
|------|------|------|------|
| 10:30 | 認証API設計 | architect | バックグラウンド実行中 |
| 10:30 | DBスキーマ設計 | architect | バックグラウンド実行中 |
| 10:31 | セキュリティ調査 | security | バックグラウンド実行中 |

---

## ✅ 本日の戦果
<!-- 完了したタスク -->

| 時刻 | 任務 | 担当 | 成果物 |
|------|------|------|--------|
| 10:25 | 要件分析 | Commander | context/project_context.md |
| 10:20 | 初期化 | Commander | CLAUDE.md, dashboard.md |

---

## 💡 学習したスキル
<!-- 承認されたスキル -->

- なし（運用中に増えていきます）

---

## 📦 公開済みプラグイン
<!-- チームに共有されたプラグイン -->

- なし

---

## 📝 直近のログ
<!-- progress.md から最新5件を抜粋 -->

最新のログは progress.md を参照
```

### 6.2 progress.md（全エージェント共有ログ）

```markdown
# 📝 作業ログ

このファイルは全エージェントが追記する共有ログです。
Commander は結果集約時にこのファイルを読んで整合性を確認します。

---

## ログ

- [10:31] security: セキュリティ要件調査を開始
- [10:30] architect: DBスキーマ設計を開始
- [10:30] architect: 認証API設計を開始
- [10:29] Commander: チームを編成、サブエージェントを起動
- [10:28] Commander: タスク分解を人間に提示、承認を得た
- [10:25] Commander: 「認証機能を実装して」を受領、要件分析完了

---

## 成果物一覧

| 時刻 | ファイル | 作成者 | 説明 |
|------|----------|--------|------|
| 10:25 | context/project_context.md | Commander | 要件定義 |

---

## スキル化候補

| 発見時刻 | 候補名 | 説明 | 発見者 | 状態 |
|----------|--------|------|--------|------|
| - | - | - | - | - |
```

---

## 7. サブエージェント定義

### 7.1 ~/.claude/agents/expert-panel.md（メタ認知用）

```markdown
---
name: expert-panel
description: |
  重要な設計判断について5人の専門家視点で熟議する。
  Use when: アーキテクチャ決定、技術選定、「どうすべきか」の相談、
  タスク分解の妥当性確認、重要な判断前のメタ認知。
model: sonnet
tools: Read, Glob, Grep
---

# Expert Panel（専門家パネル）

あなたは5人の専門家を召喚し、熟議を行うファシリテーターです。

## 召喚する専門家（議題に応じて5人選定）

### 技術系
- **Dr. Context**: LLMコンテキスト最適化、長期運用
- **Marcus Enterprise**: 組織運用、スケーラビリティ
- **田中 導入**: 日本企業の稟議・承認フロー、組織文化
- **Elena Workflow**: ドキュメント、引き継ぎ、途中参加者配慮
- **Dr. Multi-Agent**: エージェント協調、トレーサビリティ

### ビジネス系
- **Sophie Product**: ユーザー価値、優先順位
- **Alex Risk**: リスク評価、セキュリティ
- **佐藤 Ops**: 運用効率、保守性
- **Maria UX**: ユーザー体験
- **Chen Data**: データ設計、分析

## 熟議プロセス

1. **議題の明確化**: 何を決めるのか
2. **専門家選定**: 議題に最適な5人を選び、理由を述べる
3. **個別意見**: 各専門家の視点から意見を述べる
4. **討議**: 意見の相違点を明確化し、議論
5. **総意形成**: 多数決ではなく、専門家としての合意を形成
6. **推奨案**: 具体的なアクションプランを提示

## 出力形式

```
## 議題
[決定すべきこと]

## 選定した専門家
1. [名前] - 選定理由
...

## 各専門家の意見
### [専門家1]
[意見]
...

## 討議のポイント
- [相違点と議論]

## 総意
[5人の合意内容]

## 推奨アクション
1. [具体的アクション]
...
```

## 重要な原則

- 「一人の意見で決めない」: 一人の意見ではなく専門家の総意を求める
- 多数決ではない: 議論を通じた合意形成
- 権威付け: 各専門家の専門性を明確にする
```

### 7.2 .claude/agents/architect.md

```markdown
---
name: architect
description: |
  システム設計、API設計、アーキテクチャ決定を担当。
  Use for: 新機能の設計フェーズ、技術選定、構造設計。
model: sonnet
tools: Read, Write, Glob, Grep
---

# Architect（設計担当）

## 責務
- API エンドポイント設計
- データフロー設計
- コンポーネント分割
- 技術選定の提案

## 出力形式

設計ドキュメントを `.claude/docs/design_{機能名}.md` に保存:

```markdown
# 設計書: [機能名]

## 概要
[1-2行の説明]

## API設計
| Endpoint | Method | 説明 |
|----------|--------|------|
| /api/xxx | GET    | xxx  |

## データモデル
[スキーマ or ER図]

## 依存関係
- [依存するモジュール]

## 実装メモ
- [実装者への注意点]

## 判断が必要な点
- [人間に確認すべき事項]
```

## 完了時の手順

1. 設計ドキュメントを保存
2. progress.md に追記:
   ```
   - [HH:MM] architect: [何をしたか]
   - 成果物: .claude/docs/design_xxx.md
   - 次のステップ: implementer による実装
   ```
3. 判断が必要な点があれば、明確に報告に含める
4. スキル化候補（再利用できる設計パターン等）があれば報告

## 禁止事項
- 自分でコードを実装しない（設計のみ）
- 人間に直接話しかけない（Commander経由）
```

### 7.3 .claude/agents/implementer.md

```markdown
---
name: implementer
description: |
  設計に基づいてコードを実装する。
  Use for: 実装フェーズ。architect完了後に起動。
model: sonnet
tools: Read, Write, Edit, Bash, Glob, Grep
---

# Implementer（実装担当）

## 責務
- 設計書に基づく実装
- 基本的な動作確認（lint, 型チェック）

## ワークフロー

1. `.claude/docs/` から設計書を読む
2. 設計に忠実に実装
3. lint/型チェック実行
4. 完了報告

## 完了時の手順

1. コードを適切な場所に保存
2. progress.md に追記:
   ```
   - [HH:MM] implementer: [何をしたか]
   - 成果物: [ファイルパス]
   - 次のステップ: tester によるテスト
   ```
3. スキル化候補があれば報告:
   - 非自明な解決策
   - ドキュメントにない対処法
   - 再利用できそうなパターン

## 禁止事項
- 設計書にない機能を勝手に追加しない
- 人間に直接話しかけない
```

### 7.4 .claude/agents/tester.md

```markdown
---
name: tester
description: |
  テストの作成と実行を担当。
  Use for: 実装と並列、または実装完了後。
model: sonnet
tools: Read, Write, Bash, Glob, Grep
---

# Tester（テスト担当）

## 責務
- ユニットテスト作成
- 統合テスト作成
- テスト実行と結果報告

## テスト方針
- 正常系: 基本的な動作確認
- 異常系: エラーハンドリング
- 境界値: エッジケース

## 完了時の手順

1. テストファイルを作成
2. テスト実行
3. progress.md に追記:
   ```
   - [HH:MM] tester: [何をしたか]
   - 成果物: [テストファイルパス]
   - テスト結果: X passed, Y failed
   - カバレッジ: XX%
   - 次のステップ: [失敗があれば debugger、なければ reviewer]
   ```

## 禁止事項
- テスト以外のコードを書かない
- 人間に直接話しかけない
```

### 7.5 .claude/agents/reviewer.md

```markdown
---
name: reviewer
description: |
  コードレビューを担当。品質・セキュリティ・可読性を確認。
  Use for: 実装・テスト完了後の品質確認。
model: sonnet
tools: Read, Glob, Grep, Bash
---

# Reviewer（レビュー担当）

## チェック項目

### Critical（必須修正）
- セキュリティ脆弱性
- データ漏洩リスク
- 重大なバグ

### Warning（推奨修正）
- パフォーマンス問題
- エラーハンドリング不足
- テスト不足

### Suggestion（検討事項）
- 可読性改善
- リファクタリング候補
- ドキュメント追加

## 出力形式

```markdown
# レビュー結果

## Summary
- Critical: X件
- Warning: X件
- Suggestion: X件

## Critical Issues
1. [ファイル:行] [問題] [修正案]

## Warnings
...

## Suggestions
...

## 総評
[全体的な評価]
```

## 完了時の手順

1. レビュー結果を報告
2. progress.md に追記:
   ```
   - [HH:MM] reviewer: コードレビュー完了
   - 結果: Critical X件, Warning Y件, Suggestion Z件
   - 次のステップ: [Critical > 0 なら修正必要、0なら完了]
   ```

## 禁止事項
- 自分でコードを修正しない（指摘のみ）
- 人間に直接話しかけない
```

### 7.6 .claude/agents/debugger.md

```markdown
---
name: debugger
description: |
  バグの原因調査と修正を担当。
  Use for: テスト失敗時、エラー発生時、予期しない動作時。
model: sonnet
tools: Read, Write, Edit, Bash, Glob, Grep
---

# Debugger（デバッグ担当）

## デバッグプロセス

1. **情報収集**: エラーメッセージ、スタックトレース、再現手順
2. **仮説立案**: 可能性の高い原因をリストアップ
3. **検証**: ログ追加、変数確認
4. **修正**: 最小限の変更で修正
5. **確認**: テスト再実行

## 完了時の手順

1. 修正を実装
2. progress.md に追記:
   ```
   - [HH:MM] debugger: [バグ名/エラー名] を修正
   - 根本原因: [原因の説明]
   - 修正内容: [何をしたか]
   - 成果物: [修正したファイル]
   - 次のステップ: tester による再テスト
   ```
3. スキル化候補があれば報告:
   - 予想外の根本原因
   - ドキュメントにない対処法

## 禁止事項
- 原因不明のまま「とりあえず動く」修正をしない
- 人間に直接話しかけない
```

### 7.7 .claude/agents/security.md

```markdown
---
name: security
description: |
  セキュリティ要件の調査と監査を担当。
  Use for: 認証・認可設計、脆弱性調査、セキュリティレビュー。
model: sonnet
tools: Read, Glob, Grep, Bash, WebSearch
---

# Security（セキュリティ担当）

## 責務
- セキュリティ要件の調査
- 認証・認可方式の提案
- 脆弱性スキャン
- セキュリティベストプラクティスの適用

## 調査項目
- OWASP Top 10
- 認証方式（JWT, OAuth, Session等）
- 暗号化要件
- アクセス制御

## 完了時の手順

1. 調査結果をまとめる
2. progress.md に追記:
   ```
   - [HH:MM] security: [調査内容]
   - 推奨事項: [セキュリティ推奨事項]
   - 判断が必要な点: [人間に確認すべき事項]
   - 次のステップ: architect への情報提供
   ```

## 禁止事項
- セキュリティに関する重要な判断を勝手にしない
- 人間に直接話しかけない
```

---

## 8. コンテキストファイル

### 8.1 context/project_context.md（7セクション）

```markdown
# プロジェクト: [名前]

## What（これは何か）
[プロジェクトの概要、成果物の定義]

## Why（なぜやるのか）
[背景、目的、期待される効果]

## Who（誰が関係するか）
[ステークホルダー、担当者、承認者]

## Constraints（制約は何か）
[期限、予算、技術的制約、ルール]

## Current State（今どこにいるか）
[現在の進捗、直近の作業内容、次のマイルストーン]

## Decisions（決まったこと）
[意思決定の記録、誰が・いつ・何を決めたか]

## Notes（メモ・気づき）
[議事録、課題、アイデア、懸念事項]
```

### 8.2 ~/.claude/memory/preferences.md

```markdown
# ユーザーの好み

## スタイル
- シンプルイズベスト
- 過剰機能を嫌う
- 面白そうなものは試す
- 日本語でのコミュニケーション優先

## 運用ルール
- 重要な判断の前に確認を求める
- 長時間タスクはバックグラウンドで実行
- 成功したらスキル化を提案する
- 再利用価値の高いスキルはプラグイン化を提案する

## 更新履歴
- [日付]: 初期作成
```

---

## 9. スキルテンプレート

### 9.1 スキルファイルの形式

ファイルパス: `{PROJECT_ROOT}/.claude/skills/{skill-name}/SKILL.md`

```markdown
---
name: {skill-name}
description: |
  {1-3行の説明。どんな時に使うか、どんな問題を解決するかを明記。}
  Use when: {具体的なトリガー条件、エラーメッセージ、症状}
author: Claude Code (自動生成)
version: 1.0.0
date: {YYYY-MM-DD}
source_session: {セッションID or 日時}
---

# {スキル名（人間が読みやすい形式）}

## Problem（何を解決するか）
[このスキルが解決する問題の説明]

## Trigger Conditions（発動条件）
[正確なエラーメッセージ、症状、シナリオ]

例:
- エラーメッセージ: `{具体的なエラー}`
- 状況: {どんな時に発生するか}
- 前提条件: {環境、バージョン等}

## Solution（解決策）
[ステップバイステップの解決策]

1. {ステップ1}
2. {ステップ2}
3. ...

## Code Example（コード例）
```{言語}
{解決策のコード例}
```

## Verification（検証方法）
[うまくいったことを確認する方法]

## Related（関連情報）
- 関連スキル: {あれば}
- 参考リンク: {あれば}
- 注意事項: {あれば}
```

### 9.2 品質ゲート（スキル化しない条件）

以下に該当する場合はスキル化しない：

- 単なるドキュメント参照（調べればわかる）
- 1回限りの特殊ケース（再利用価値なし）
- 検証されていない（本当に動くか不明）
- 一般的すぎる（「エラーが出たら直す」レベル）

---

## 10. スキルのプラグイン化とチーム共有 🔍 **要確認**

### 10.1 概要

育てたスキルをプラグイン形式に変換し、チーム内で共有する。

> ⚠️ **構文注意**: 以下の手順は Claude の知識にない最新機能です。
> 実行前に公式ドキュメントで正確な構文を確認してください。
> https://docs.anthropic.com/en/docs/claude-code/plugins

### 10.2 共有方法の優先順位

| 優先度 | 方式 | 概要 | 適用条件 |
|--------|------|------|----------|
| 1 | プラグイン化 + チーム用マーケットプレース | スキルをプラグイン形式に変換し公開 | 公式機能が利用可能な場合 |
| 2 | 社内レジストリ | GitHub org 等にプラグインリポジトリを作成 | 方式1が困難な場合 |
| 3 | Git共有 | `.claude/skills/` をGitリポジトリで共有 | 最もシンプルなフォールバック |

### 10.3 方式1: プラグイン化 + チーム用マーケットプレース

#### 10.3.1 スキルをプラグイン形式に変換

```bash
# 🔍 要確認: 実際のコマンドは公式ドキュメントを参照

# 1. スキルディレクトリに移動
cd .claude/skills/{skill-name}

# 2. プラグイン形式に変換（推測される構文）
# ⚠️ 構文注意: 以下は想定される構文。実際の構文は公式ドキュメントで確認
/plugin init --from-skill .

# または手動でプラグイン構造を作成
```

#### 10.3.2 プラグインの構造（想定）

```
.claude/plugins/{plugin-name}/
├── plugin.json          # プラグインメタデータ
├── SKILL.md             # スキル本体
├── README.md            # 説明
└── examples/            # 使用例
    └── example.md
```

#### 10.3.3 plugin.json の形式（想定）

```json
{
  "name": "{plugin-name}",
  "version": "1.0.0",
  "description": "スキルの説明",
  "author": "{チーム名 or 個人名}",
  "license": "MIT",
  "keywords": ["keyword1", "keyword2"],
  "skills": ["SKILL.md"],
  "dependencies": []
}
```

#### 10.3.4 チーム用マーケットプレースへの公開

```bash
# 🔍 要確認: 実際のコマンドは公式ドキュメントを参照

# 1. チーム用マーケットプレースを作成（初回のみ）
# GitHub リポジトリを作成: {org}/claude-plugins

# 2. マーケットプレースを登録
/plugin marketplace add {org}/claude-plugins

# 3. プラグインを公開
/plugin publish {plugin-name} --marketplace {org}/claude-plugins
```

### 10.4 方式2: 社内レジストリ（GitHub org）

公式のプラグイン化機能が利用できない場合のフォールバック。

#### 10.4.1 リポジトリ構造

```
{org}/claude-team-skills/
├── README.md
├── plugins/
│   ├── prisma-pool-fix/
│   │   ├── SKILL.md
│   │   └── README.md
│   ├── nextjs-auth-pattern/
│   │   ├── SKILL.md
│   │   └── README.md
│   └── ...
└── CONTRIBUTING.md
```

#### 10.4.2 共有手順

```bash
# 1. リポジトリをクローン
git clone git@github.com:{org}/claude-team-skills.git

# 2. スキルをコピー
cp -r .claude/skills/{skill-name} claude-team-skills/plugins/

# 3. コミット & プッシュ
cd claude-team-skills
git add .
git commit -m "Add {skill-name} skill"
git push

# 4. チームメンバーはシンボリックリンクで利用
ln -s ~/claude-team-skills/plugins/{skill-name} ~/.claude/skills/{skill-name}
```

### 10.5 方式3: Git共有（シンプル）

最もシンプルなフォールバック。プロジェクトリポジトリ内でスキルを共有。

```bash
# .claude/skills/ を .gitignore から除外
echo "!.claude/skills/" >> .gitignore

# スキルをコミット
git add .claude/skills/{skill-name}
git commit -m "Add {skill-name} skill"
git push
```

### 10.6 Commander への指示（CLAUDE.md に追記）

```markdown
## スキルのプラグイン化

スキルが以下の条件を満たす場合、プラグイン化を提案する：

**プラグイン化候補の条件**:
- 他のプロジェクトでも再利用できる
- チーム内の複数人が恩恵を受ける
- 十分に検証され、安定している
- 機密情報を含まない

**提案の仕方**:
1. dashboard.md の「プラグイン化候補」に追加
2. 人間に「このスキルはチーム共有の価値があります。プラグイン化しますか？」と確認
3. 承認後、プラグイン化手順を実行

**プラグイン化の手順**:
1. 🔍 公式ドキュメントでプラグイン化の最新手順を確認
2. スキルをプラグイン形式に変換
3. チーム用マーケットプレースに公開（または社内レジストリにpush）
4. dashboard.md の「公開済みプラグイン」に追加
```

---

## 11. 実装手順

### Phase 1: バックアップと準備

```bash
# 1. バージョン確認
claude --version
# 2.1.0 以上であることを確認

# 2. バックアップ
mkdir -p ~/.claude/backup/$(date +%Y%m%d_%H%M%S)
cp -r ~/.claude/* ~/.claude/backup/$(date +%Y%m%d_%H%M%S)/ 2>/dev/null || true

# 3. ディレクトリ作成
mkdir -p ~/.claude/{agents,memory}
mkdir -p .claude/{agents,skills,plugins,docs}
mkdir -p context
```

### Phase 2: グローバルファイル作成

1. `~/.claude/agents/expert-panel.md` を作成（7.1参照）
2. `~/.claude/memory/preferences.md` を作成（8.2参照）

### Phase 3: プロジェクトファイル作成

1. `CLAUDE.md` を作成（セクション5の内容）
2. `.claude/agents/architect.md` を作成（7.2参照）
3. `.claude/agents/implementer.md` を作成（7.3参照）
4. `.claude/agents/tester.md` を作成（7.4参照）
5. `.claude/agents/reviewer.md` を作成（7.5参照）
6. `.claude/agents/debugger.md` を作成（7.6参照）
7. `.claude/agents/security.md` を作成（7.7参照）

### Phase 4: ダッシュボードとログ作成

1. `dashboard.md` を作成（6.1参照、初期状態で空のテーブル）
2. `progress.md` を作成（6.2参照、初期状態）
3. `context/project_context.md` を作成（8.1参照）

### Phase 5: プラグインインストール 🔍 **要確認**

```bash
# 🔍 要確認: コマンド構文は公式ドキュメントで確認すること

# マーケットプレース追加
/plugin marketplace add wshobson/agents
/plugin marketplace add affaan-m/everything-claude-code
/plugin marketplace add anthropics/claude-code

# プラグインインストール
/plugin install code-documentation@wshobson/agents
/plugin install debugging-toolkit@wshobson/agents
/plugin install business-analytics@wshobson/agents
/plugin install everything-claude-code@affaan-m/everything-claude-code
/plugin install plugin-dev@anthropics/claude-code
```

### Phase 6: 動作確認

```bash
# Claude Code を起動
claude

# エージェント一覧を確認
/agents

# 以下が表示されることを確認:
# - expert-panel (user)
# - architect (project)
# - implementer (project)
# - tester (project)
# - reviewer (project)
# - debugger (project)
# - security (project)

# プラグイン一覧を確認
/plugins

# テスト: 簡単なタスクを依頼
You: 簡単なREADME.mdを作成して

# Commander が:
# 1. タスク分解を提示するか確認
# 2. サブエージェントを起動するか確認
# 3. dashboard.md を更新するか確認
# 4. progress.md にログが追記されるか確認
```

---

## 12. 使い方ガイド

### 基本的な使い方

```
# 1. プロジェクトディレクトリでClaude Codeを起動
cd your-project
claude

# 2. タスクを依頼
You: ユーザー認証機能を実装して

# 3. Commander がタスク分解を提示
[Commander]
タスクを分解しました：
1. security: 認証方式の調査（JWT vs OAuth）
2. architect: 認証API設計
3. architect: DBスキーマ設計
4. implementer: 実装（設計完了後）
5. tester: テスト作成

この分解で進めてよいですか？

# 4. 承認
You: いいよ

# 5. Commander がサブエージェントを起動
[Commander]
チームを起動しました。dashboard.md で進捗を確認できます。
（security, architect x2 がバックグラウンドで並列実行）

# 6. dashboard.md をエディタで開いてプレビュー
#    Cmd+Shift+V でMarkdownプレビュー表示

# 7. 判断が必要な時は Commander が聞いてくる
[Commander]
security から報告がありました。
JWT と OAuth、どちらを採用しますか？
理由も教えてください。

# 8. 判断を伝える
You: JWTで。理由はシンプルだから。

# 9. スキル化候補が出たら
[Commander]
implementer からスキル化候補が報告されました：
「Prisma接続プール枯渇の解決法」
dashboard.md の「スキル化候補」に追加しました。
承認しますか？

You: 承認

# 10. プラグイン化の提案
[Commander]
このスキルは他のプロジェクトでも再利用できそうです。
チームに共有するためプラグイン化しますか？

You: お願い

# 11. 完了
[Commander]
全タスク完了しました。
progress.md で整合性を確認...問題ありません。
dashboard.md を更新しました。
```

### メタ認知を使いたい時

```
You: このアーキテクチャで大丈夫か不安。専門家に相談して

[Commander]
expert-panel を起動します。

[expert-panel が5人の専門家を召喚して熟議]

[Commander]
専門家パネルの結論:
- マイクロサービスは時期尚早
- まずはモノリスで、後から分割を推奨
- 5人全員が同意

この方針で進めますか？
```

### 失敗時のプラグイン検索

```
You: Kubernetes のデプロイを設定して

[Commander]
Kubernetes の設定を試みましたが、適切なスキルが不足しています。

関連プラグインを検索しました:
- kubernetes-ops@wshobson/agents

このプラグインをインストールしますか？

You: お願い

[Commander]
インストールしました。再試行します。
```

---

## 13. 成功基準（受け入れテスト）

### テスト1: タスク分解とメタ認知

```
シナリオ:
1. 「認証機能を実装して」と依頼
2. Commander がタスク分解を提示
3. 人間が承認
4. サブエージェントが起動

期待結果:
- タスク分解が提示される（いきなり実行しない）
- 人間の承認後にサブエージェントが起動
```

### テスト2: ダッシュボード更新

```
シナリオ:
1. サブエージェントが起動される
2. dashboard.md を確認
3. サブエージェントが完了
4. dashboard.md を確認

期待結果:
- 起動時に「進行中」に追加される
- 完了時に「戦果」に移動する
```

### テスト3: progress.md ログ

```
シナリオ:
1. サブエージェントが作業完了
2. progress.md を確認

期待結果:
- 作業ログが追記されている
- 成果物のパスが記載されている
- 次のステップが記載されている
```

### テスト4: 専門家パネル

```
シナリオ:
1. 「専門家に相談して」と依頼
2. expert-panel が起動

期待結果:
- 5人の専門家が選定される
- 各専門家の意見が個別に述べられる
- 総意が形成される
```

### テスト5: スキル化フロー

```
シナリオ:
1. サブエージェントがスキル化候補を報告
2. dashboard.md に追加される
3. 人間が「承認」
4. スキルファイルが生成される

期待結果:
- dashboard.md の「スキル化候補」に表示
- 承認後 .claude/skills/ にファイル作成
```

### テスト6: プラグイン化フロー 🔍 **要確認**

```
シナリオ:
1. スキルが承認された後、Commander がプラグイン化を提案
2. 人間が「承認」
3. スキルがプラグイン形式に変換される

期待結果:
- dashboard.md の「プラグイン化候補」に表示
- 承認後、プラグイン形式に変換
- チーム用マーケットプレース（または社内レジストリ）に公開
- dashboard.md の「公開済みプラグイン」に追加

⚠️ 注意: プラグイン化の具体的な手順は公式ドキュメントで確認すること
```

### テスト7: プラグイン検索・インストール 🔍 **要確認**

```
シナリオ:
1. タスクが失敗
2. Commander が関連プラグインを検索
3. 人間に提案
4. 承認後インストール

期待結果:
- `/plugin search` で関連プラグインが見つかる
- 人間の承認後にインストールされる
- 再試行で成功する

⚠️ 注意: コマンド構文は公式ドキュメントで確認すること
```

---

## 14. トラブルシューティング

### Commander がタスク分解せずに実行してしまう

```
原因: CLAUDE.md の指示が読み込まれていない
対処: 
1. CLAUDE.md が存在するか確認
2. 「CLAUDE.md を読み直して」と指示
3. セッションを再起動
```

### サブエージェントが progress.md に書かない

```
原因: サブエージェントへの指示に含め忘れ
対処:
1. サブエージェント定義を確認
2. 「完了時の手順」セクションがあるか確認
3. Commander のプロンプトで明示的に指示
```

### dashboard.md が更新されない

```
原因: Commander が更新を忘れている
対処: 「dashboard.md を更新して」と指示
```

### コンパクション後に混乱する

```
対処: 
1. 「CLAUDE.md を読み直して」
2. 「dashboard.md と progress.md を読んで現状を把握して」
```

### プラグインコマンドが動かない 🔍 **要確認**

```
原因: コマンド構文が変更されている可能性
対処:
1. 公式ドキュメントで最新の構文を確認
   https://docs.anthropic.com/en/docs/claude-code/plugins
2. `/help plugin` でヘルプを表示
3. 構文を修正して再実行
```

### マーケットプレースが見つからない

```
原因: マーケットプレースのURLが変更されている可能性
対処:
1. 公式ドキュメントで利用可能なマーケットプレースを確認
2. GitHub リポジトリが存在するか確認
3. 代替のマーケットプレースを検索
```

---

## 15. 制約事項

### 公式機能の制約
- サブエージェントはサブエージェントを spawn できない（2層まで）
- 並列実行はトークン消費が激しい（Pro上限に注意）
- バックグラウンドタスクは長時間放置するとタイムアウトの可能性

### 運用上の注意
- 重要な判断は人間が行う（Commander が必ず確認）
- 機密情報はスキル/プラグインに含めない
- progress.md が肥大化したら定期的にアーカイブ

### 最新機能に関する注意 🔍 **要確認**
- プラグイン関連のコマンド構文は公式ドキュメントで確認すること
- マーケットプレースの仕様は変更される可能性がある
- チーム用マーケットプレースの作成方法は公式ドキュメントを参照

---

## 16. 参考資料

### 公式ドキュメント
- Subagents: https://docs.anthropic.com/en/docs/claude-code/sub-agents
- Background Tasks: https://docs.anthropic.com/en/docs/claude-code/background-tasks
- Plugins: https://docs.anthropic.com/en/docs/claude-code/plugins
- Skills: https://docs.anthropic.com/en/docs/claude-code/skills

### 参考実装
- multi-agent-shogun: https://github.com/yohey-w/multi-agent-shogun
- shogun ブログ: https://zenn.dev/shio_shoppaize/articles/5fee11d03a11a1
- progress.md パターン: https://www.theaistack.dev/p/orchestrating-claude-sub-agents
- Claude Code Swarm: https://gist.github.com/kieranklaassen/4f2aba89594a4aea4ad64d753984b2ea

### プラグインマーケットプレース 🔍 **要確認**
- wshobson/agents: https://github.com/wshobson/agents
- affaan-m/everything-claude-code: https://github.com/affaan-m/everything-claude-code
- anthropics/claude-code: https://github.com/anthropics/claude-code

---

## 17. 変更履歴

| バージョン | 日付 | 変更内容 |
|------------|------|----------|
| v4 | - | 初版（2層構造、サブエージェント、ダッシュボード） |
| v5 | - | マーケットプレースからのプラグイン導入、スキルのプラグイン化・チーム共有を追加 |

---

**この要件定義書に従って実装を開始してください。**
**🔍 マークの箇所は、実装前に公式ドキュメントで最新の構文を確認してください。**
**不明点がある場合は、実装前に質問してください。**
