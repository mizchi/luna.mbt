# Sol App Benchmarks

k6 を使用したベンチマークスクリプト。

## セットアップ

```bash
# k6 インストール (macOS)
brew install k6
```

## 使い方

サーバーを起動した状態で実行:

```bash
# ターミナル1: サーバー起動
npm run dev
# または
npm run serve  # 本番ビルド後

# ターミナル2: ベンチマーク実行
npm run bench          # フルベンチマーク (smoke + load + stress)
npm run bench:quick    # クイックテスト (10秒)
npm run bench:static   # 静的ルートのみ
npm run bench:dynamic  # 動的ルートのみ
npm run bench:api      # API エンドポイントのみ
```

## ベンチマークスクリプト

| スクリプト | 対象ルート | VUs | 時間 |
|-----------|-----------|-----|------|
| `static-routes.js` | `/`, `/about`, `/form`, `/admin` | 10 | 30s |
| `dynamic-routes.js` | `/docs/[...slug]`, `/blog/[[...path]]` | 10 | 30s |
| `api-routes.js` | `/api/health`, `/api/middleware-test` | 10 | 30s |
| `all.js` | 全ルート | 5→50 | smoke + load + stress |

## カスタム実行

```bash
# VUs と時間を指定
k6 run --vus 20 --duration 60s bench/static-routes.js

# 別のホストを指定
k6 run -e BASE_URL=http://localhost:8080 bench/all.js

# JSON 出力
k6 run --out json=results.json bench/all.js
```

## 結果

ベンチマーク結果は `bench/results/` に JSON 形式で保存されます。
