# sol_api - Pure REST API Example

MoonBit + Sol で構築する Pure REST API サーバーの例。

## 特徴

- **HTML なし**: 純粋な JSON API サーバー
- **REST パターン**: Items リソースの読み取り操作
- **ミドルウェア**: CORS, Logger, Security Headers
- **エラーハンドリング**: 構造化されたエラーレスポンス

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/health` | ヘルスチェック |
| GET | `/api/items` | アイテム一覧 |
| GET | `/api/items/:id` | 単一アイテム取得 |
| GET | `/api/stats` | 統計情報 |
| GET | `/api/error?type=xxx` | エラーレスポンステスト |

## 使い方

```bash
# ビルド
just all

# サーバー起動
just serve

# API テスト (別ターミナルで)
just test-api
just test-errors
```

## レスポンス例

```bash
# Health check
curl http://localhost:7777/api/health
# => {"status":"ok","timestamp":"2024-01-29T12:00:00.000Z"}

# List items
curl http://localhost:7777/api/items
# => {"items":[{"id":1,"name":"Item 1",...}],"total":3}

# Get single item
curl http://localhost:7777/api/items/1
# => {"id":1,"name":"Item 1","description":"First item","created_at":"..."}

# Item not found
curl http://localhost:7777/api/items/99
# => {"error":"not_found","message":"Item not found"}

# Error response
curl "http://localhost:7777/api/error?type=not_found"
# => {"error":"not_found","message":"Resource not found"}
```

## ミドルウェア構成

1. **CORS**: 全オリジン許可、主要 HTTP メソッド対応
2. **Logger**: リクエストログ出力
3. **Security Headers**: X-Content-Type-Options, X-Frame-Options

## vs 他の例題

| 例題 | 特徴 |
|------|------|
| sol_app | フルスタック (Islands, WC, Server Actions) |
| sol_auth | 認証・認可 (Better Auth) |
| sol_blog | SSG ブログ |
| sol_docs | ドキュメントサイト (SPA) |
| sol_sqlite | ISR + SQLite |
| **sol_api** | **Pure REST API (この例題)** |
