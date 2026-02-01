# トラブルシューティング

このドキュメントには、実際に発生した問題と解決方法を記録します。

---

## エージェントが認識されない（Agent type 'xxx' not found）

**発生日**: 2026-02-01

### 症状

```
Task({
  subagent_type: "architect",
  ...
})
```

を実行すると以下のエラー:

```
Agent type 'architect' not found. Available agents: Bash, general-purpose, ...
```

- `.claude/agents/architect.md` は存在する
- フロントマターも記述されている
- しかし認識されない

### 根本原因

**`allowed-tools` は非標準フィールド**

公式ドキュメント（https://code.claude.com/docs/en/sub-agents.md）の仕様:

| 正しい | 間違い |
|--------|--------|
| `tools: Read, Write, Glob, Grep` | ❌ `allowed-tools: ...` |

### 解決方法

**1. 全エージェントファイルを修正**

```bash
# すべてのエージェントファイルを確認
grep -l "allowed-tools" .claude/agents/*.md

# 各ファイルで置換: allowed-tools → tools
```

**2. ドキュメント・テンプレートも修正**

```bash
# ドキュメント内のサンプルコードも修正
grep -r "allowed-tools" docs/ templates/
```

**3. 新しいセッションで確認**

```bash
# セッション再起動（エージェント再読み込み）
exit
claude

# エージェント一覧を確認
/agents
```

### 正しいフロントマター形式

```yaml
---
name: architect
description: システム設計を担当。Use for: 設計フェーズ
model: sonnet
tools: Read, Write, Glob, Grep  # ✅ 正しい
---
```

### 学習ポイント

1. **小さなエラーでも無視しない** - タイポではなく仕様の問題
2. **公式ドキュメントで確認** - claude-code-guideエージェントを活用
3. **全体への影響を確認** - 1ファイルだけでなく全体を修正
4. **修正を永続化** - ドキュメントに記録（このファイル）

### 参考

- [公式ドキュメント: Subagents](https://code.claude.com/docs/en/sub-agents.md)
- [claude-code-guide調査結果](../progress.md)（agentId: a2b1c11）

---

## その他の問題

今後、問題が発生したらこのセクションに追加していきます。

### テンプレート

```markdown
## [問題の簡潔な説明]

**発生日**: YYYY-MM-DD

### 症状
[何が起こったか]

### 根本原因
[なぜ起こったか]

### 解決方法
[どう解決したか]

### 学習ポイント
[何を学んだか]
```
