#!/bin/bash

# セッション終了時の学び永続化リマインダー

echo ""
echo "=========================================="
echo "⚠️  セッション終了チェック"
echo "=========================================="
echo ""
echo "以下を確認してください："
echo ""
echo "1. 今日の学びを永続化しましたか？"
echo "   - 新しい問題 → troubleshooting.md"
echo "   - 新しい原則 → CLAUDE.md or スキル化"
echo ""
echo "2. dashboard.md は最新ですか？"
echo "   - 進行中タスクは空か、引き継ぎ事項として記録"
echo "   - 本日の成果は記録済み"
echo ""
echo "3. 未コミットの変更はありますか？"
echo ""

# 未コミットの変更をチェック
cd "$CLAUDE_PROJECT_DIR" 2>/dev/null
if [ -d ".git" ]; then
  CHANGES=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  if [ "$CHANGES" -gt 0 ]; then
    echo "📝 未コミットの変更: ${CHANGES}件"
    echo ""
  fi
fi

echo "=========================================="
echo ""
