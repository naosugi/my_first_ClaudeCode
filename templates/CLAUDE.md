# プロジェクト: [プロジェクト名]

## 概要
[プロジェクトの1-2文の説明]

## よく使うコマンド

```bash
# 開発サーバー起動
npm run dev

# テスト実行
npm test

# ビルド
npm run build
```

## ディレクトリ構造

```
src/
├── components/    # UIコンポーネント
├── pages/         # ページコンポーネント
├── utils/         # ユーティリティ関数
└── types/         # 型定義
```

## コードスタイル

- TypeScript使用
- 関数は単一責任に
- コメントは「なぜ」を説明

## 重要なファイル

- `src/config.ts` - 設定ファイル
- `src/api/client.ts` - APIクライアント

## 禁止事項

- .envファイルの内容をコミットしない
- main ブランチへの直接プッシュ禁止

## トラブルシューティング

### よくあるエラー
- `Module not found` → `npm install` を実行
- `Port already in use` → 既存プロセスを終了

---
*このファイルは簡潔に保つこと。各行について「これを削除したらClaudeが間違いを犯すか？」と問う*
