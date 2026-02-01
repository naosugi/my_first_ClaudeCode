#!/bin/bash
# pre-commit-check.sh - git commit 前の検証フック
# Claude Code PreToolUse hook として動作

set -euo pipefail

# stdin から JSON を読み取り
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# git commit コマンドでない場合はスキップ
if [[ ! "$COMMAND" =~ ^git[[:space:]]+commit ]]; then
  exit 0
fi

# ステージングエリアのファイル一覧を取得
STAGED_FILES=$(git diff --cached --name-only 2>/dev/null || echo "")

# 空なら何もしない
if [ -z "$STAGED_FILES" ]; then
  exit 0
fi

# --- チェック1: .DS_Store ---
if echo "$STAGED_FILES" | grep -q '\.DS_Store'; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": ".DS_Store がステージングされています。git reset HEAD .DS_Store を実行してください。"
  }
}
EOF
  exit 0
fi

# --- チェック2: node_modules ---
if echo "$STAGED_FILES" | grep -q '^node_modules/'; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "node_modules/ をコミットしようとしています。.gitignore を確認してください。"
  }
}
EOF
  exit 0
fi

# --- チェック3: 機密ファイル ---
if echo "$STAGED_FILES" | grep -Eq '\.(env|env\.local|key|pem|p12|credentials)$'; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "機密ファイル（.env, .key, .pem等）をコミットしようとしています。"
  }
}
EOF
  exit 0
fi

# --- チェック4: 大きすぎるファイル（5MB以上） ---
while IFS= read -r file; do
  if [ -n "$file" ] && [ -f "$file" ]; then
    SIZE=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo 0)
    if [ "$SIZE" -gt 5242880 ]; then
      SIZE_MB=$((SIZE / 1048576))
      cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "大きすぎるファイル（5MB以上）: $file (${SIZE_MB}MB)"
  }
}
EOF
      exit 0
    fi
  fi
done <<< "$STAGED_FILES"

# すべてのチェックをパス
exit 0
