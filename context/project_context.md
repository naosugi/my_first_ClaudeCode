# プロジェクト: Claude Code セットアップキット for Mac

## What（これは何か）
Mac向けのClaude Codeセットアップキット。
新規ユーザーがClaude Codeを使い始めるための環境構築を支援する。

## Why（なぜやるのか）
- Claude Codeの初期設定は複雑で、ベストプラクティスが散在している
- 特にMac環境での設定手順をまとめた日本語リソースが不足
- Commander experienceの知見を活かした効率的な開発環境を提供したい

## Who（誰が関係するか）
- 対象ユーザー: Mac上でClaude Codeを使い始める開発者
- メンテナ: naosugi
- 貢献者: Claude Code コミュニティ

## Constraints（制約は何か）
- Claude Code v2.1.x 以上が必要
- Pro プラン ($20/月) 推奨
- macOS 環境限定

## Current State（今どこにいるか）
- Phase 1-3 完了: マーケットプレース追加、プラグインインストール、基本構造作成
- 次のマイルストーン: 動作確認、ドキュメント更新

## Decisions（決まったこと）
| 日付 | 決定事項 | 理由 |
|------|----------|------|
| 2026-02-01 | Commander experience v5 を適用 | 効率的なマルチエージェント開発環境のため |
| 2026-02-01 | 2層構造（Commander + サブエージェント） | Claude Code公式機能の制約内で最大効果 |

## Notes（メモ・気づき）
- プラグインコマンドはセッション内スラッシュコマンドではなく、CLIから実行
- `claude plugin marketplace add` / `claude plugin install` の形式
- everything-claude-code のプラグインは plugins/ ではなく skills/, agents/ 等に配置
