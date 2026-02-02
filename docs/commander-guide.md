# Claude Code Commander体験ガイド

**読了時間: 20分**

「ダッシュボードを眺めて、たまに話しかけるだけ」でタスクが進む自動化体験

---

## 目次

1. [Commander体験とは](#commander体験とは)
2. [何ができるのか](#何ができるのか)
3. [仕組み](#仕組み)
4. [セットアップ](#セットアップ)
5. [使い方](#使い方)
6. [スキルの育成](#スキルの育成)
7. [トラブルシューティング](#トラブルシューティング)

---

## Commander体験とは

### 従来の使い方

```
あなた: 認証機能を実装して

Claude Code: [実装する]

あなた: テストも書いて

Claude Code: [テストを書く]

あなた: レビューして

Claude Code: [レビューする]
```

一つひとつ指示を出し、待ち、次の指示を出す...

### Commander体験

```
あなた: 認証機能を実装して

Commander: タスクを分解しました：
  1. security: 認証方式の調査
  2. architect: API設計
  3. implementer: 実装
  4. tester: テスト作成
  5. reviewer: レビュー

  この分解で進めてよいですか？

あなた: いいよ

Commander: チーム起動しました。
  dashboard.md で進捗を確認できます。

[あなたは dashboard.md を眺めながらコーヒーを飲む]

─── 15分後 ───

Commander: 全タスク完了。問題ありません。
  次のフェーズに進みますか？
```

**あなたがするのは**:
- 最初に「何をしたいか」を伝える
- タスク分解を承認する
- dashboard.md を眺める（Markdownプレビュー）
- たまに話しかける（判断が必要な時だけCommanderが聞いてくる）

---

## 何ができるのか

### 1. タスク自動分解と委譲

Commander（大臣+幹部の役割を統合）が自動的にタスクを分解し、適切なサブエージェント（係員）に委譲します。

```
認証機能を実装 →
  ├─ security（係員）: セキュリティ要件調査
  ├─ architect（係員）: API設計
  ├─ implementer（係員）: 実装
  ├─ tester（係員）: テスト作成
  └─ reviewer（係員）: レビュー
```

### 2. 並列実行

依存関係のないタスクは並列で実行されます。

```
認証機能 + 管理画面 →
  ├─ [並列] architect: 認証API設計
  ├─ [並列] architect: 管理画面設計
  └─ [順次] implementer: 実装（設計完了後）
```

### 3. メタ認知（専門家パネル）

重要な判断の前に、5人の専門家を召喚して熟議します。

```
Commander: JWT vs OAuth、どちらを採用すべきか
  expert-panel に相談します。

[5人の専門家が議論]
  - Dr. Security: OAuth推奨
  - Alex Enterprise: JWTで十分
  - 田中導入: 承認フローを考慮するとJWT
  - ...

Commander: 専門家パネルの結論: JWT推奨
  理由: [詳細な理由]

  この方針で進めますか？
```

### 4. 進捗の可視化

dashboard.md をエディタで開いてプレビュー表示（Cmd+Shift+V）すると、リアルタイムで進捗が確認できます。

```markdown
# 状況報告

## 進行中
| 時刻 | 任務 | 担当 | 状態 |
| 10:30 | API設計 | architect | 実行中 |
| 10:30 | DB設計 | architect | 実行中 |

## 要対応
- JWT vs OAuth どちらを採用？

## 本日の成果
| 10:25 | 要件分析 | Commander | 完了 |
```

### 5. スキルの育成

サブエージェントが「再利用できる解決策」を発見すると、スキル化を提案します。

```
implementer: Prisma接続プール枯渇の解決法を発見しました。
  スキル化候補として dashboard.md に追加しました。

Commander: このスキルを保存しますか？
  今後、同じ問題が発生したら自動的に解決できます。

あなた: 承認

[.claude/skills/ にスキルが保存される]
```

---

## 仕組み

### アーキテクチャ

```
┌─────────────────────────────────────────────────────────────────┐
│ メインセッション（Commander = 大臣 + 幹部の役割を統合）         │
│                                                                 │
│ 【大臣の役割】                                                  │
│   - 人間からの指示を受領                                        │
│   - 方針決定、最終判断                                          │
│   - 人間との唯一の窓口                                          │
│                                                                 │
│ 【幹部の役割】                                                  │
│   - タスク分解（適切か自問してから実行）                        │
│   - サブエージェント起動・管理                                  │
│   - 結果集約、dashboard.md 更新                                 │
│   - 重要判断前に expert-panel でメタ認知                        │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│ サブエージェント群（係員たち）                                  │
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

### Commanderの行動原則

1. **即座に委譲せよ、ただし確認してから**
   - タスクを受けたら、まず分解案を作成
   - 「この分解で適切か？」と自問する
   - 不安があれば expert-panel を呼んで検討
   - 人間に分解案を提示し、承認を得る
   - 承認後、サブエージェントを並列起動

2. **メタ認知を怠るな**
   - タスク分解時: 「この粒度で適切か？」
   - 重要な技術判断: expert-panel で5人の専門家に相談
   - 結果集約時: progress.md を読んで整合性確認
   - 人間への報告前: 「この報告で判断できるか？」

3. **ダッシュボードを常に更新せよ**
   - サブエージェント起動時 → 「進行中」に追加
   - サブエージェント完了時 → 「成果」に移動
   - 判断が必要な時 → 「要対応」に追加

---

## セットアップ

### 前提条件

- Claude Code 2.1.0 以上
- Pro プラン ($20/月)
- 30分程度の時間

### Step 1: プラグインのインストール

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

**期待される出力**:
```
Installed plugins:

  ❯ business-analytics@claude-code-workflows
  ❯ code-documentation@claude-code-workflows
  ❯ debugging-toolkit@claude-code-workflows
  ❯ plugin-dev@claude-plugins-official
```

### Step 2: ディレクトリ構造の作成

```bash
# プロジェクトルートで実行
cd your-project

# プロジェクト固有ディレクトリ
mkdir -p .claude/{agents,skills,docs}
mkdir -p context

# グローバルディレクトリ
mkdir -p ~/.claude/{agents,memory}
```

### Step 3: ファイルの作成

**3.1 グローバルファイル**

`~/.claude/agents/expert-panel.md`:
```markdown
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

## 出力形式

- 議題
- 選定した専門家（選定理由付き）
- 各専門家の意見
- 討議のポイント
- 総意
- 推奨アクション
```

`~/.claude/memory/preferences.md`:
```markdown
# ユーザーの好み

## スタイル
- シンプルイズベスト
- 過剰機能を嫌う
- 日本語でのコミュニケーション優先

## 運用ルール
- 重要な判断の前に確認を求める
- 長時間タスクはバックグラウンドで実行
- 成功したらスキル化を提案する
```

**3.2 プロジェクトファイル**

このリポジトリの `.claude/agents/` にあるサブエージェント定義をコピーするか、
プロジェクトで `claude` を起動して以下のように指示:

```
このプロジェクトにCommander環境をセットアップして。

以下のファイルを作成:
- CLAUDE.md（Commander定義）
- dashboard.md（戦況報告）
- progress.md（作業ログ）
- .claude/agents/ 配下のサブエージェント

参照: このリポジトリの .claude/agents/ と templates/
```

### Step 4: 動作確認

```bash
# 新しいセッションを開始（CLAUDE.mdを読み込むため）
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

---

## 使い方

### 基本フロー

```
1. プロジェクトディレクトリでClaude Codeを起動
   $ cd your-project
   $ claude

2. やりたいことを伝える
   > ユーザー認証機能を実装して

3. Commanderがタスク分解を提示
   [Commander]
   タスクを分解しました：
   1. security: 認証方式の調査
   2. architect: API設計
   ...

   この分解で進めてよいですか？

4. 承認する
   > いいよ

5. dashboard.mdをエディタで開いてプレビュー
   （Cmd+Shift+V でMarkdownプレビュー）

6. たまに話しかける
   - 判断が必要な時はCommanderが聞いてくる
   - スキル化候補が出たら承認/却下

7. 完了
   [Commander]
   全タスク完了しました。
   問題ありません。
```

### dashboard.mdの見方

エディタで `dashboard.md` を開き、Markdownプレビュー（Cmd+Shift+V）で表示:

```markdown
# 状況報告

## 要対応
<!-- あなたの判断が必要な項目 -->

### スキル化候補【承認待ち】
- 1番: Prisma接続プール枯渇の解決法
  → 承認する場合は「1番承認」

### 判断待ち
- JWT vs OAuth どちらを採用？

## 進行中
<!-- 現在作業中のタスク -->
| 時刻 | 任務 | 担当 | 状態 |
| 10:30 | API設計 | architect | 実行中 |

## 本日の成果
<!-- 完了したタスク -->
| 10:25 | 要件分析 | Commander | 完了 |
```

**リアルタイム更新**: サブエージェントが作業を進めると自動的に更新されます。

### メタ認知を使う

重要な判断で迷ったら:

```
> このアーキテクチャで大丈夫か不安。専門家に相談して

[Commander]
expert-panel を起動します。

[5人の専門家が熟議]

[Commander]
専門家パネルの結論:
- マイクロサービスは時期尚早
- まずはモノリスで、後から分割を推奨
- 5人全員が同意

この方針で進めますか？
```

### 失敗時のプラグイン検索

うまくいかない場合、Commanderが自動的にプラグインを探します:

```
[Commander]
Kubernetes の設定を試みましたが、適切なスキルが不足しています。

関連プラグインを検索しました:
- kubernetes-ops@claude-code-workflows

このプラグインをインストールしますか？

> お願い

[Commander]
インストールしました。再試行します。
```

---

## スキルの育成

### スキル化の流れ

```
1. サブエージェントが非自明な解決策を発見
   ↓
2. dashboard.md の「スキル化候補」に自動追加
   ↓
3. あなたが承認
   ↓
4. .claude/skills/ に保存
   ↓
5. 次回から自動的に活用される
```

### スキル化の例

**状況**: implementer が Prisma接続プール枯渇の問題を解決

```
[Commander]
implementer からスキル化候補が報告されました：

「Prisma接続プール枯渇の解決法」
- 問題: Prisma Client の接続プール枯渇
- 解決策: グローバルインスタンス化とシングルトンパターン
- 再利用価値: 高（Prisma使用プロジェクトで共通）

承認しますか？

> 承認

[Commander]
スキルを保存しました: .claude/skills/prisma-pool-fix/

今後、同じ問題が発生したら自動的に解決します。
```

### プラグイン化（チーム共有）

スキルが他のプロジェクトでも使える場合、プラグイン化を提案します:

```
[Commander]
このスキルは他のプロジェクトでも再利用できそうです。
チームに共有するためプラグイン化しますか？

> お願い

[Commander]
プラグイン化しました: .claude/plugins/prisma-pool-fix/
チームメンバーは以下でインストールできます:

  claude plugin install prisma-pool-fix@your-org/plugins
```

---

## トラブルシューティング

### Q: Commanderがタスク分解せずに実行してしまう

**原因**: CLAUDE.md が読み込まれていない

**対処**:
```
> CLAUDE.md を読み直して

# または
$ exit
$ claude  # 新しいセッションを開始
```

### Q: サブエージェントが progress.md に書かない

**原因**: サブエージェント定義に「完了時の手順」がない

**対処**:
1. `.claude/agents/*.md` を確認
2. 「完了時の手順」セクションがあるか確認
3. なければ追加

### Q: dashboard.md が更新されない

**原因**: Commander が更新を忘れている

**対処**:
```
> dashboard.md を更新して
```

### Q: コンパクション後に混乱する

**原因**: 長いセッションで要約（compaction）が発生し、コンテキストが失われた

**対処**:
```
> CLAUDE.md を読み直して
> dashboard.md と progress.md を読んで現状を把握して
```

**予防策**:
- 長時間セッションは避ける（1-2時間で区切る）
- 重要な情報は CLAUDE.md に書く

### Q: プラグインコマンドが動かない

**確認**:
```bash
# マーケットプレース一覧
claude plugin marketplace list

# プラグイン一覧
claude plugin list

# 正しい構文
claude plugin marketplace add wshobson/agents
claude plugin install code-documentation@claude-code-workflows
```

**注意**:
- `/plugin` ではなく `claude plugin`（CLIコマンド）
- マーケットプレース名はGitHubリポジトリ名と異なる場合がある

---

## まとめ

| 従来の使い方 | Commander体験 |
|-------------|-----------|
| 一つひとつ指示を出す | 最初に目的を伝えるだけ |
| 待って、次の指示 | ダッシュボードを眺める |
| 全部自分で考える | 専門家パネルに相談 |
| 毎回同じ問題を解決 | スキル化して自動化 |

**ゴール**:
> タスクを「する」のではなく、「任せる」

**次のステップ**:
1. [セットアップ](#セットアップ)を実行
2. 簡単なタスクで試す
3. dashboard.md を眺める感覚を掴む
4. スキルを育てていく

---

**参考資料**:
- [詳細セットアップガイド](./setup-guide.md)
