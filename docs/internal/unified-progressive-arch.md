# Unified Progressive Architecture

Astra (SSG) と Sol (SSR) をシームレスに統合し、段階的に MPA → SPA → SSR へ移行可能なアーキテクチャ設計。

## 背景と課題

### 現状の問題

| 課題 | 詳細 |
|------|------|
| ルーティング方式の不一致 | Astra: ファイルベース, Sol: 宣言的(SolRoutes型) |
| 移行の断絶 | 静的→動的に変えるとき、ルート定義を全て書き直す必要がある |
| MoonBitの制約 | ビルド後にソースファイル名が消えるため、実行時にファイル名でルーティングできない |

### 設計目標

1. ファイルベースルーティングと明示的ルーティングの共存
2. 段階的な移行パス: MPA ⇔ SPA-CSR ⇔ SSR+CSR
3. 実装パターンに依存しない中間表現
4. Cloudflare Workers を想定したデプロイ

---

## ディレクトリ構造

```
src/pages/
├── page.json                 # ルート / の設定
├── index.mbt                 # / のレンダラー
├── about/
│   ├── page.json            # /about の設定
│   └── index.mbt            # /about のレンダラー
├── blog/
│   ├── page.json            # /blog の設定
│   ├── index.mbt            # /blog (一覧)
│   └── _slug_/              # 動的セグメント (:slug)
│       ├── page.json        # /blog/:slug の設定
│       └── index.mbt        # /blog/:slug のレンダラー
├── docs/
│   ├── page.json
│   ├── index.md             # Markdown ページ
│   ├── guide/
│   │   ├── intro.md         # /docs/guide/intro
│   │   └── advanced.mdx     # /docs/guide/advanced (MDX)
│   └── _catchall_/          # catch-all (/docs/*)
│       └── index.mbt
├── app/
│   ├── page.json            # mode: "spa", fallback: true
│   └── index.mbt            # SPA エントリポイント
└── api/
    ├── page.json            # API ルート設定
    └── posts/
        ├── page.json
        └── index.mbt        # GET /api/posts
```

### 命名規則

| パターン | 意味 | 例 |
|----------|------|-----|
| `index.mbt` | そのセグメントのページ | `/about/index.mbt` → `/about` |
| `_name_/` | 動的パラメータ | `/_slug_/` → `/:slug` |
| `_catchall_/` | catch-all | `/_catchall_/` → `/*` |

### 対応拡張子

| 拡張子 | 処理 | 出力 |
|--------|------|------|
| `.mbt` | MoonBit関数を呼び出し | VNode → HTML |
| `.md` | Markdown → HTML変換 | HTML (レイアウト適用) |
| `.mdx` | MDX → HTML + Islands | HTML + hydration |
| `.html` | そのまま配信 | passthrough |

---

## page.json スキーマ

```json
{
  "$schema": "https://luna.dev/schemas/page.json",

  // レンダリングモード
  "mode": "static",           // "static" | "ssr" | "isr" | "spa"
  "revalidate": 3600,         // ISR: 秒数 (mode: "isr" のとき)

  // メタデータ
  "title": "Blog Post",
  "description": "...",
  "layout": "blog",           // layouts/blog.mbt を使用

  // Islands (クライアントで hydrate するコンポーネント)
  "islands": ["counter", "comment-form"],

  // 動的ルートのパラメータ生成 (static/isr時)
  "generateParams": true,     // getStaticPaths 相当

  // SPA フォールバック
  "fallback": true,           // このセグメント配下を全て index.html にフォールバック

  // 継承設定
  "extends": "../page.json",  // 親の設定を継承

  // ファイル種別ごとの設定
  "handlers": {
    ".md": { "layout": "doc" },
    ".mdx": { "layout": "doc", "islands": ["*"] },
    ".html": { "passthrough": true }
  }
}
```

### 設定の継承

```
src/pages/
├── page.json                 # mode: "static" (デフォルト)
└── blog/
    ├── page.json             # extends: "../page.json", layout: "blog"
    └── _slug_/
        └── page.json         # mode: "ssr" (このセグメントだけSSR)
```

マージ順: `ルート page.json` → `親 page.json` → `現在の page.json`

---

## 中間データ構造: RouteManifest

実装パターンに依存しない中間表現。

```moonbit
pub struct RouteManifest {
  routes : Array[RouteEntry]
  fallback : FallbackConfig
}

pub enum RouteEntry {
  // 静的ページ（ビルド時にHTML生成可能）
  Static(StaticRoute)
  // 動的ページ（リクエスト時に生成）
  Dynamic(DynamicRoute)
  // API エンドポイント
  Api(ApiRoute)
}

pub struct StaticRoute {
  path : String              // "/about"
  source : String            // "about/index.mbt"
  output : String            // "about/index.html"
  layout : String?
  title : String?
}

pub struct DynamicRoute {
  path : String              // "/blog/:slug"
  pattern : String           // 正規表現
  param_names : Array[String] // ["slug"]
  source : String
  mode : RenderMode          // Ssr | Isr(revalidate)
  layout : String?
}

pub struct ApiRoute {
  path : String
  pattern : String
  method : HttpMethod        // Get | Post | Put | Delete | All
  source : String
}

pub enum FallbackConfig {
  // 404ページ
  NotFound(path : String)
  // SPA: 全て index.html にフォールバック
  Spa(entry : String)
  // 特定パス配下だけSPA
  SpaPrefix(prefix : String, entry : String)
}

pub enum RenderMode {
  Ssr
  Isr(revalidate : Int)  // 秒数
}
```

---

## ビルドフロー

```
src/pages/
    │
    ▼ (スキャン)
┌─────────────────────────────┐
│      RouteManifest          │  ← 中間表現
│  - routes: [...]            │
│  - fallback: Spa("/app")    │
└─────────────────────────────┘
    │
    ├─────────────────┬─────────────────┬─────────────────┐
    ▼                 ▼                 ▼                 ▼
┌─────────┐    ┌───────────┐    ┌───────────┐    ┌─────────────┐
│ Static  │    │ CFW       │    │ Node/Hono │    │ SPA Client  │
│ HTML    │    │ Router    │    │ Router    │    │ Router      │
└─────────┘    └───────────┘    └───────────┘    └─────────────┘
    │                │                │                │
    ▼                ▼                ▼                ▼
  dist/         _worker.js      server.js       app.js
```

### 静的 vs 動的 の判定

```
RouteManifest を走査:
  │
  ├── 全て Static? ──────► 純粋静的サイト
  │                         └── HTML出力のみ、ルーター不要
  │
  ├── Dynamic あり? ──────► Hybrid
  │                         ├── Static → HTML出力
  │                         └── Dynamic → ルーターで処理
  │
  └── fallback: Spa? ────► SPA領域
                            └── 該当パスは entry.html にフォールバック
```

---

## Cloudflare Workers 向け出力

```
dist/
├── _routes.json              # CFW用ルート設定
├── _worker.js                # 動的ルート処理
├── index.html                # /
├── about/index.html          # /about
├── blog/index.html           # /blog (静的一覧)
└── app/index.html            # /app/* のSPAエントリ
```

**_routes.json** (CFW形式):
```json
{
  "version": 1,
  "include": ["/*"],
  "exclude": [
    "/about",
    "/blog",
    "/assets/*"
  ]
}
```

`exclude` されたパスは静的アセットから直接返却、それ以外は `_worker.js` で処理。

---

## 段階的移行パス

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Phase 1: MPA   │ ──► │  Phase 2: Hybrid│ ──► │  Phase 3: SSR   │
│                 │     │                 │     │                 │
│ output: static  │     │ output: hybrid  │     │ output: server  │
│ 全ページ .md    │     │ 一部 .mbt + SSR │     │ 全ページ動的    │
│ サーバー不要    │     │ サーバー必要    │     │ フルダイナミック│
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

### 変更点だけで移行可能

1. `luna.config.json` の `output` を変更
2. 動的にしたいページの `page.json` に `mode: "ssr"` を追加

---

## luna.config.json

プロジェクト全体の設定。

```json
{
  "output": "hybrid",          // "static" | "hybrid" | "server"

  "routing": {
    "mode": "file-based",      // "file-based" | "explicit" | "hybrid"
    "pages": "src/pages",
    "explicit": "src/routes.mbt"
  },

  "layouts": "src/layouts",
  "public": "public",
  "outDir": "dist",

  "build": {
    "minify": true,
    "sourcemap": false
  },

  "dev": {
    "port": 3000,
    "hmr": true
  }
}
```

---

## 明示的ルーティングとの共存

既存の Remix 風パターンも維持。

```moonbit
// 明示的定義（既存）
pub fn routes() -> Array[SolRoutes] {
  [
    SolRoutes::Page(path="/", handler=home, ...),
    SolRoutes::Page(path="/about", handler=about, ...),
  ]
}

// ファイルベース定義からも同じ RouteManifest を生成
pub fn scan_pages(dir : String) -> RouteManifest

// 両方をマージ可能
pub fn merge_manifests(
  explicit : RouteManifest,
  file_based : RouteManifest
) -> RouteManifest
```

`routing.mode` で切り替え:
- `file-based`: ファイルベースのみ
- `explicit`: 明示的定義のみ
- `hybrid`: 両方をマージ（明示的定義が優先）

---

## 動的ルートのパラメータ生成

静的ビルド時に動的ルートのパラメータを列挙。

**page.json**:
```json
{
  "mode": "static",
  "generateParams": true
}
```

**index.mbt**:
```moonbit
// 静的生成時に呼ばれる
pub fn get_static_params() -> Array[Map[String, String]] {
  [
    { "slug": "hello-world" },
    { "slug": "second-post" },
  ]
}

// レンダリング
pub fn render(params : RouteParams) -> VNode {
  let slug = params.get("slug")
  // ...
}
```

---

## 制約事項

### 対応しないもの

- **多段動的ルート**: `/_category_/_slug_/` のような複数の動的セグメントのネスト（一意に決定できないため）

### 将来の拡張候補

- 多段動的ルートのサポート（明示的な優先度指定付き）
- Edge Functions 対応
- Streaming SSR

---

## 実装計画

1. **RouteManifest 型定義** - 中間表現の型を固める
2. **page.json パーサー** - 設定ファイルの読み込み
3. **ディレクトリスキャナー** - pages/ を走査して RouteManifest 生成
4. **ジェネレーター**
   - Static HTML 出力
   - CFW _worker.js 生成
   - Hono サーバー生成
   - SPA クライアントルーター生成
