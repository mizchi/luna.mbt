# Cloudflare Hybrid Static/Dynamic Routing

静的コンテンツはCDNから高速配信し、動的ルートのみWorkerで処理するハイブリッド設計。

## 概要

```
┌─────────────────────────────────────────────┐
│  Cloudflare CDN Edge                        │
│  (静的ファイル: HTML, CSS, JS, images)        │
└─────────────────────┬───────────────────────┘
                      │ run_worker_first
                      ▼
┌─────────────────────────────────────────────┐
│  Cloudflare Worker (Sol)                    │
│  - API routes (/api/*)                      │
│  - ISR pages (/blog/:slug)                  │
│  - Auth-required pages (/admin/*)           │
└─────────────────────────────────────────────┘
```

## Route Analyzer

`@router.analyze_routes()` でSolRoutesから動的ルートを抽出：

```moonbit
// 動的ルートの判定基準
// 1. API routes (Get, Post) -> 常に動的
// 2. ISR pages (revalidate != None) -> 動的
// 3. Dynamic path params (:id, [slug]) -> 動的
// 4. Catch-all routes ([...slug]) -> 動的
// 5. その他 -> 静的
```

## 使用方法

### 1. ルート定義

```moonbit
// routes.mbt
pub fn routes() -> Array[@router.SolRoutes] {
  [
    @router.with_mw([@mw.logger()], [
      // 静的ページ - CDNから配信
      @router.page("/", home, title="Home"),
      @router.page("/about", about, title="About"),

      // ISRページ - Workerで処理
      @router.page("/blog/:slug", blog_post, title="Blog", revalidate=Some(60)),

      // API - Workerで処理
      @router.api_get("/api/users/:id", get_user),
      @router.api_post("/api/users", create_user),
    ]),
  ]
}
```

### 2. wrangler.json生成

```moonbit
// 解析してwrangler設定を生成
pub fn generate_deploy_config() -> String {
  @router.generate_wrangler_assets_config(routes(), "./dist")
}
```

### 3. ビルドスクリプト

```bash
# moon build
moon build --target js

# wrangler.json生成
node -e "
import { generate_deploy_config } from './dist/server.js';
import { writeFileSync } from 'node:fs';
writeFileSync('wrangler.json', JSON.stringify({
  name: 'my-site',
  main: './dist/worker.js',
  assets: JSON.parse(generate_deploy_config())
}, null, 2));
"
```

### 4. 生成されるwrangler.json

```json
{
  "name": "my-site",
  "main": "./dist/worker.js",
  "assets": {
    "directory": "./dist",
    "html_handling": "auto-trailing-slash",
    "not_found_handling": "single-page-application",
    "run_worker_first": [
      "/api/*",
      "/blog/*"
    ]
  }
}
```

## API Reference

### analyze_routes(routes)

SolRoutesを解析し、各ルートの分類を返す。

```moonbit
pub fn analyze_routes(routes : Array[SolRoutes]) -> Array[AnalyzedRoute]

pub enum RouteKind {
  Static   // 静的ルート - CDNから配信
  Dynamic  // 動的ルート - Workerで処理
}

pub struct AnalyzedRoute {
  pattern : String    // URLパターン
  kind : RouteKind    // 分類
  reason : String     // 分類理由
}
```

### extract_dynamic_patterns(routes)

動的ルートのパターンをCloudflare形式で抽出。

```moonbit
pub fn extract_dynamic_patterns(routes : Array[SolRoutes]) -> Array[String]

// 変換例:
// /user/:id        -> /user/*
// /docs/[...slug]  -> /docs/*
// /api/health      -> /api/health
```

### generate_wrangler_assets_config(routes, output_dir)

wrangler.jsonのassets設定を生成。

```moonbit
pub fn generate_wrangler_assets_config(
  routes : Array[SolRoutes],
  output_dir : String,
) -> String
```

## 動的ルート判定ロジック

| ルート種別 | 判定 | 理由 |
|-----------|------|------|
| API (Get/Post) | Dynamic | ランタイム処理が必要 |
| ISR (revalidate設定あり) | Dynamic | バックグラウンド再検証が必要 |
| Path params (`:id`, `[id]`) | Dynamic | 値がビルド時に不明 |
| Catch-all (`[...slug]`) | Dynamic | パス数が不定 |
| 静的パス | Static | ビルド時に生成可能 |

## 参考

- [Cloudflare Workers Static Assets](https://developers.cloudflare.com/workers/static-assets/)
- [run_worker_first Configuration](https://developers.cloudflare.com/workers/static-assets/routing/worker-script/)
