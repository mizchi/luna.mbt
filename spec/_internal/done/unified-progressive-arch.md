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
├── counter/                  # SSR コンポーネント
│   ├── moon.pkg.json        # パッケージ定義
│   ├── page.json            # mode: "static", staticParams: [...]
│   ├── client/              # クライアントコード
│   │   ├── moon.pkg.json
│   │   └── counter.mbt      # CounterProps, counter関数
│   └── server/              # サーバーコード
│       ├── moon.pkg.json
│       └── index.mbt        # render_ssr
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

| 拡張子/構造 | 処理 | 出力 |
|-------------|------|------|
| `.mbt` | MoonBit関数を呼び出し | VNode → HTML |
| `.md` | Markdown → HTML変換 | HTML (レイアウト適用) |
| `.mdx` | MDX → HTML + Islands | HTML + hydration |
| `.html` | そのまま配信 | passthrough |
| `moon.pkg.json` ディレクトリ | コンポーネント検出 | SSR + Hydration |

### コンポーネントディレクトリ

`moon.pkg.json` を含むディレクトリは、Luna コンポーネントとして認識される。

**ディレクトリ構造:**

```
counter/                      # コンポーネントディレクトリ
├── moon.pkg.json            # パッケージ定義
├── page.json                # ページ設定 (mode, staticParams 等)
├── client/                  # クライアントコード (Hydration)
│   ├── moon.pkg.json
│   └── counter.mbt          # Props, render関数
└── server/                  # サーバーコード (SSR)
    ├── moon.pkg.json
    └── index.mbt            # SSRレンダラー
```

**コンポーネント判定ルール:**

| 構造 | 判定 | 動作 | Lint |
|------|------|------|------|
| `client/` + `server/` | SSR コンポーネント | SSR + Hydration | - |
| `client/` のみ | Client-only | Hydration のみ（静的HTMLなし） | Warning |
| `server/` のみ | Server-only | SSR のみ（Hydration なし） | Info |

SSR コンポーネントの場合:
- `server/` で HTML を生成（静的ビルド or リクエスト時）
- `client/` で Hydration を実行

---

## page.json スキーマ

```json
{
  "$schema": "https://luna.dev/schemas/page.json",

  // レンダリングモード
  "mode": "static",           // "static" | "ssr" | "isr" | "spa"
  "revalidate": 3600,         // ISR: 秒数 (mode: "isr" のとき有効)

  // メタデータ
  "title": "Blog Post",
  "description": "...",
  "layout": "blog",           // layouts/blog.mbt を使用

  // Islands (クライアントで hydrate するコンポーネント)
  "islands": ["counter", "comment-form"],

  // 動的ルートの静的パラメータ (static/isr時にビルド)
  "staticParams": [
    { "slug": "hello-world" },
    { "slug": "second-post" }
  ],

  // SPA フォールバック
  "fallback": true,           // このセグメント配下を全て index.html にフォールバック

  // 継承設定
  "extends": "../page.json",  // 親の設定を継承

  // ファイル種別ごとの設定
  "handlers": {
    ".md": { "layout": "doc" },
    ".mdx": { "layout": "doc", "islands": ["*"] },
    ".html": { "passthrough": true }
  },

  // コンポーネントディレクトリ用設定
  "component": {
    "propsType": "CounterProps",   // Props 構造体名
    "clientExport": "counter",     // client/ のエクスポート関数名
    "serverExport": "render_ssr"   // server/ のエクスポート関数名
  }
}
```

### コンポーネント用 page.json 例

**静的ビルド:**

```json
{
  "mode": "static",
  "staticParams": [
    { "id": "1", "initialCount": 0 },
    { "id": "2", "initialCount": 10 }
  ],
  "component": {
    "propsType": "CounterProps",
    "clientExport": "counter",
    "serverExport": "render_ssr"
  }
}
```

**ISR (Incremental Static Regeneration):**

```json
{
  "mode": "isr",
  "revalidate": 3600,
  "staticParams": [
    { "id": "popular-1" },
    { "id": "popular-2" }
  ],
  "component": {
    "propsType": "CounterProps",
    "clientExport": "counter",
    "serverExport": "render_ssr"
  }
}
```

**SSR (完全動的):**

```json
{
  "mode": "ssr",
  "component": {
    "propsType": "CounterProps",
    "clientExport": "counter",
    "serverExport": "render_ssr"
  }
}
```

`staticParams` で指定した各パラメータセットに対して、ビルド時に静的 HTML を生成する。
`staticParams` にないパラメータは:
- `mode: "static"` → 404
- `mode: "isr"` → 初回リクエスト時に生成してキャッシュ
- `mode: "ssr"` → 毎回リクエスト時に生成

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
  // SSR コンポーネント
  Component(ComponentRoute)
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

/// SSR コンポーネントルート
pub struct ComponentRoute {
  path : String              // "/counter"
  source : String            // "counter/"
  component_type : ComponentType
  mode : RenderMode
  layout : String?
  // 静的生成されたパス一覧
  static_paths : Array[StaticPathEntry]
}

pub enum ComponentType {
  // client/ + server/ → SSR + Hydration
  SsrComponent
  // client/ のみ → Hydration のみ
  ClientOnlyComponent
  // server/ のみ → SSR のみ
  ServerOnlyComponent
}

pub struct StaticPathEntry {
  params : Map[String, String]
  output : String            // "counter/1/index.html"
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

### 静的アセットバインディング

Cloudflare Workers の[静的アセットバインディング](https://developers.cloudflare.com/workers/static-assets/binding/)を活用し、
パフォーマンスを最適化する。

**wrangler.json 設定:**

```json
{
  "assets": {
    "directory": "./dist",
    "binding": "ASSETS",
    "run_worker_first": false
  }
}
```

`run_worker_first: false` により、静的ファイルがあれば Worker をスキップ。

**設計原則:**

- **デフォルトは静的** - 明示的にサーバー機能を有効にしない限り Worker 不要
- **オプトイン** - `mode: "ssr"` や動的 layout を使用した場合のみ Worker が必要
- **パスごとに選択可能** - 静的/クライアントルーター/サーバールーターを混在可能

**`run_worker_first` の自動判定:**

| 条件 | `run_worker_first` | 理由 |
|------|-------------------|------|
| 全ページ静的 | `false` (デフォルト) | Worker 不要 |
| 動的 layout あり | `true` | ルートで Worker 処理が必要 |
| 一部 SSR ページあり | `false` | 該当パスのみ Worker 処理 |

ユーザーがこの設定を意識する必要はないが、設計側は理解しておく必要がある。

**動作:**

1. リクエストが来る
2. 静的ファイルが存在する → Cloudflare が直接返却（Worker 起動なし）
3. 静的ファイルがない → Worker (`_worker.js`) で動的処理

これにより、静的ビルド可能なページは Worker のコールドスタートを回避できる。

### 出力ディレクトリ構造

```
dist/
├── _routes.json              # CFW用ルート設定
├── _worker.js                # 動的ルート処理
├── index.html                # / (静的)
├── about/index.html          # /about (静的)
├── blog/index.html           # /blog (静的一覧)
├── counter/                  # コンポーネント
│   ├── index.html            # /counter (静的 SSR)
│   └── _client.js            # Hydration スクリプト
└── app/index.html            # /app/* のSPAエントリ
```

### ルーティング設定

**_routes.json** (CFW形式):
```json
{
  "version": 1,
  "include": ["/*"],
  "exclude": [
    "/about",
    "/blog",
    "/counter",
    "/assets/*"
  ]
}
```

`exclude` されたパスは静的アセットから直接返却、それ以外は `_worker.js` で処理。

### パスごとのルーティングモード

ユーザーはパスごとに以下のモードを選択できる：

| モード | 設定 | ビルド時 | ランタイム |
|--------|------|----------|------------|
| **静的** | `mode: "static"` | HTML 生成 | Cloudflare 直接配信 |
| **SSR** | `mode: "ssr"` | なし | Worker でレンダリング |
| **ISR** | `mode: "isr"` | 初回 HTML 生成 | 期限切れ時に Worker で再生成 |
| **SPA** | `mode: "spa"` | index.html のみ | クライアントルーターで処理 |

**混在例:**

```
/              → 静的 (HTML)
/about         → 静的 (HTML)
/blog          → 静的 (一覧 HTML)
/blog/:slug    → ISR (初回生成後キャッシュ)
/app/*         → SPA (クライアントルーター)
/dashboard/*   → SSR (認証必要)
```

### 静的 vs 動的の判定フロー

```
ビルド時:
  RouteManifest を走査
    │
    ├── mode: "static" ────► HTML ファイルを生成 → _routes.json の exclude に追加
    │
    ├── mode: "ssr" ───────► Worker でハンドル（静的ファイルなし）
    │
    ├── mode: "spa" ───────► index.html 生成 → fallback 設定
    │
    ├── mode: "isr" ────────► staticParams から HTML 生成 + Worker でフォールバック
    │
    └── staticParams あり (static/isr)
          │
          ├── page.json の staticParams を読み込み
          │
          └── 各パラメータで HTML 生成 → exclude に追加
              (mode: "isr" の場合、未生成パラメータは Worker で動的処理)
```

### クライアントナビゲーション

異なるモード間を遷移する際のクライアントルーターの挙動を定義する。

**遷移マトリクス:**

| From ↓ / To → | 静的 | SPA | SSR |
|---------------|------|-----|-----|
| **静的** | `<a>` or fetch | フルリロード | fetch HTML |
| **SPA** | フルリロード | 内部遷移 | フルリロード |
| **SSR** | fetch HTML | フルリロード | fetch HTML |

**遷移戦略:**

| 戦略 | 動作 | 適用場面 |
|------|------|----------|
| **フルリロード** | `location.href = url` | モード境界を跨ぐ遷移（シンプル） |
| **fetch HTML** | fetch → innerHTML swap | 同モード内、または静的→SSR |
| **内部遷移** | History API + render | SPA 内のみ |

**推奨パターン:**

```
┌─────────────────────────────────────────────────────────────┐
│                      ナビゲーション判定                      │
└─────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        ▼                     ▼                     ▼
   ┌─────────┐          ┌─────────┐          ┌─────────┐
   │ 同一SPA │          │ 静的/SSR │         │ SPA境界 │
   │  内遷移  │          │  間遷移   │         │  を跨ぐ  │
   └────┬────┘          └────┬────┘          └────┬────┘
        │                     │                     │
        ▼                     ▼                     ▼
   History API           fetch HTML            フルリロード
   + クライアント         + swap                location.href
     レンダリング
```

**実装の選択肢:**

1. **シンプル（推奨初期実装）**
   - SPA 外への遷移は全てフルリロード
   - 実装コスト: 低
   - UX: 遷移時に白画面あり

2. **ハイブリッド（Turbo/HTMX 風）**
   - 静的/SSR 間は fetch + swap
   - SPA 境界はフルリロード
   - 実装コスト: 中
   - UX: 静的ページ間はスムーズ

3. **統一ルーター（フル SPA）**
   - 全ルートをクライアントで管理
   - SSR ページも fetch HTML でハイドレーション
   - 実装コスト: 高
   - UX: 最もスムーズ

設定は `luna.config.json` の `navigation.strategy` で指定する。

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

## パフォーマンス設計

クライアントランタイムを最小限に抑え、必要な機能のみを選択的にロードする。

### 設計原則

| 原則 | 説明 |
|------|------|
| **最小ベースライン** | 全ページで最小限の loader + router をロード |
| **エンドポイント別チャンク** | 各ページに必要なチャンクのみを初期ロード |
| **差分ロード** | SPA 遷移時は不足分のチャンクを追加ロード |

### クライアントモジュール構成

```
@luna/client
├── boot/           # ベースランタイム (常にロード, < 2KB)
│   ├── loader.js   # チャンクローダー、依存解決
│   └── router.js   # 最小ルーター (リンク intercept, prefetch)
├── hydrate/        # Hydration (< 1KB)
│   └── island.js   # Island hydration
├── signal/         # リアクティブランタイム (< 1KB)
│   └── runtime.js  # Signal 更新処理
├── router/         # 拡張ルーター (オプション)
│   ├── hybrid.js   # fetch + swap 方式 (< 1KB)
│   └── spa.js      # フル SPA ルーター (< 2KB)
└── islands/        # 個別 Island チャンク
    ├── counter.js
    └── comment.js
```

### ビルドフロー (Rolldown)

```
ソースコード
    │
    ▼ (Rolldown でバンドル)
┌─────────────────────────────────────────────────────────┐
│                    チャンク生成                          │
├─────────────────────────────────────────────────────────┤
│  共通チャンク:                                           │
│    boot.[hash].js      # loader + router (全ページ共通)  │
│    signal.[hash].js    # Signal ランタイム               │
│    hydrate.[hash].js   # Island hydration               │
│                                                         │
│  ルーターチャンク:                                        │
│    router-hybrid.[hash].js                              │
│    router-spa.[hash].js                                 │
│                                                         │
│  Island チャンク:                                        │
│    island-counter.[hash].js                             │
│    island-comment.[hash].js                             │
│                                                         │
│  ページチャンク:                                         │
│    page-app.[hash].js  # SPA エントリ                    │
└─────────────────────────────────────────────────────────┘
    │
    ▼ (エンドポイントごとにマニフェスト生成)
┌─────────────────────────────────────────────────────────┐
│  /_luna/manifest.json                                   │
│  {                                                      │
│    "/": ["boot", "hydrate", "island-counter"],          │
│    "/blog": ["boot", "hydrate"],                        │
│    "/app": ["boot", "signal", "router-spa", "page-app"] │
│  }                                                      │
└─────────────────────────────────────────────────────────┘
```

### ページ種別ごとのロード戦略

| ページ種別 | 初期ロード | 合計サイズ目標 |
|------------|-----------|---------------|
| **静的 (Islands なし)** | `boot` | < 2 KB |
| **静的 + Islands** | `boot` + `hydrate` + `signal` + islands | < 4 KB + islands |
| **SSR + Hydration** | `boot` + `hydrate` + `signal` + islands | < 4 KB + islands |
| **Hybrid ナビゲーション** | `boot` + `router-hybrid` | < 3 KB |
| **SPA エントリ** | `boot` + `signal` + `router-spa` + page | < 5 KB + page |

### 初期ロードと差分ロード

**初期ロード:**

```html
<!-- /blog/hello-world (静的 + Islands) -->
<html>
  <head>
    <!-- 必要なチャンクを modulepreload -->
    <link rel="modulepreload" href="/_luna/boot.abc123.js">
    <link rel="modulepreload" href="/_luna/hydrate.def456.js">
    <link rel="modulepreload" href="/_luna/island-counter.ghi789.js">
  </head>
  <body>
    <div data-island="counter" data-props='{"count":0}'>...</div>
  </body>
  <script type="module">
    import { boot } from '/_luna/boot.abc123.js';
    boot(['/blog/hello-world']);  // このページに必要なチャンクをロード
  </script>
</html>
```

**SPA 遷移時の差分ロード:**

```
現在のページ: /blog/hello-world
ロード済み: [boot, hydrate, signal, island-counter]

遷移先: /app
必要: [boot, signal, router-spa, page-app]

差分計算:
  - 既にロード済み: boot, signal
  - 追加ロード: router-spa, page-app
```

```javascript
// boot/loader.js の実装イメージ
const loaded = new Set(['boot', 'hydrate', 'signal', 'island-counter']);

async function navigate(path) {
  const manifest = await fetch('/_luna/manifest.json').then(r => r.json());
  const required = manifest[path] || manifest['*'];
  const missing = required.filter(chunk => !loaded.has(chunk));

  // 不足分を並列ロード
  await Promise.all(missing.map(chunk => import(`/_luna/${chunk}.js`)));
  missing.forEach(chunk => loaded.add(chunk));

  // ページをレンダリング
  render(path);
}
```

### boot/loader.js の役割

```
boot/loader.js
├── loadChunks()    # マニフェストに基づきチャンクをロード
├── prefetch()      # リンクホバー時に次ページのチャンクをプリフェッチ
├── lazyLoad()      # Island の遅延ロード (Intersection Observer)
└── getLoaded()     # ロード済みチャンク一覧を取得
```

**boot/router.js の役割:**

```
boot/router.js
├── intercept()     # <a> クリックをインターセプト
├── navigate()      # 差分ロード + ページ遷移
├── prefetchLink()  # リンクの先読み
└── onNavigate()    # 遷移イベントハンドラ登録
```

**遅延ロードの設定 (page.json):**

```json
{
  "islands": [
    { "name": "heavy-chart", "lazy": true, "threshold": "50vh" }
  ]
}
```

### 出力ディレクトリ構造

```
dist/
├── _luna/
│   ├── manifest.json            # エンドポイント → チャンク マッピング
│   ├── boot.[hash].js           # loader + router (全ページ共通)
│   ├── hydrate.[hash].js        # Island hydration
│   ├── signal.[hash].js         # Signal ランタイム
│   ├── router-hybrid.[hash].js  # Hybrid ルーター (オプション)
│   ├── router-spa.[hash].js     # SPA ルーター (オプション)
│   ├── island-counter.[hash].js # 個別 Island
│   └── island-comment.[hash].js
├── pages/
│   └── app.[hash].js            # SPA エントリ
├── index.html
├── blog/
│   └── hello-world/index.html
└── app/index.html
```

### パフォーマンス目標

| 指標 | 目標値 | 備考 |
|------|--------|------|
| **boot (ベースライン)** | < 2 KB (gzip) | 全ページで常にロード |
| **boot + hydrate + signal** | < 4 KB (gzip) | Islands ありの場合 |
| **フル SPA ランタイム** | < 6 KB (gzip) | boot + signal + router-spa |
| **LCP** | < 1.5s | Lighthouse |
| **TTI (Islands)** | < 2.0s | Lighthouse |
| **FID** | < 100ms | Core Web Vitals |

### Rolldown 設定

```javascript
// rolldown.config.js
export default {
  input: {
    boot: './src/client/boot/index.js',
    hydrate: './src/client/hydrate/index.js',
    signal: './src/client/signal/index.js',
    'router-hybrid': './src/client/router/hybrid.js',
    'router-spa': './src/client/router/spa.js',
    // Islands は自動検出
  },
  output: {
    dir: 'dist/_luna',
    format: 'esm',
    entryFileNames: '[name].[hash].js',
    chunkFileNames: '[name].[hash].js',
    manualChunks: (id) => {
      // 共通依存は boot にまとめる
      if (id.includes('node_modules')) return 'boot';
    }
  },
  plugins: [
    lunaManifestPlugin()  // manifest.json を生成
  ]
};
```

### luna.config.json でのパフォーマンス設定

```json
{
  "performance": {
    "inlineThreshold": 1024,      // bytes 以下の JS はインライン化
    "prefetch": "hover",          // "hover" | "visible" | "none"
    "lazyIslands": false,         // Islands のデフォルト遅延ロード
    "modulePreload": true,        // <link rel="modulepreload">
    "bundler": "rolldown"         // "rolldown" | "esbuild"
  }
}
```

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
  },

  "navigation": {
    "strategy": "simple",      // "simple" | "hybrid" | "unified"
    "prefetch": true,          // リンクホバー時に prefetch
    "scrollRestoration": true  // スクロール位置の復元
  },

  "performance": {
    "inlineThreshold": 1024,   // bytes 以下の JS はインライン化
    "prefetch": "hover",       // "hover" | "visible" | "none"
    "lazyIslands": false,      // Islands のデフォルト遅延ロード
    "modulePreload": true      // <link rel="modulepreload">
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

静的ビルド時に動的ルートのパラメータを `page.json` で宣言的に定義する。

### page.json での定義

```json
{
  "mode": "static",
  "staticParams": [
    { "slug": "hello-world" },
    { "slug": "second-post" }
  ]
}
```

### ISR での定義

```json
{
  "mode": "isr",
  "revalidate": 3600,
  "staticParams": [
    { "slug": "popular-post" }
  ]
}
```

ISR の場合:
- `staticParams` に含まれるパスはビルド時に生成
- それ以外は初回アクセス時に生成してキャッシュ
- `revalidate` 秒後にバックグラウンドで再生成

### レンダリング側 (index.mbt)

```moonbit
// パラメータを受け取ってレンダリング
pub fn render(params : RouteParams) -> VNode {
  let slug = params.get("slug")
  // ...
}
```

### staticParams の動的生成

外部データソースからパラメータを取得する必要がある場合は、
ビルド前のスクリプトで `page.json` を生成する。

**MoonBit でスクリプトを書く場合:**

```
scripts/
├── moon.pkg.json       # { "main": "generate_params.mbt" }
└── generate_params.mbt
```

```moonbit
// scripts/generate_params.mbt
fn main {
  // CMS API から記事一覧を取得
  let articles = fetch_articles_from_cms()

  // staticParams を構築
  let params = articles.map(fn(a) { { "slug": a.slug } })

  // page.json を生成
  let page_json = {
    "mode": "isr",
    "revalidate": 3600,
    "staticParams": params
  }

  @fs.writeFileSync("src/pages/blog/_slug_/page.json", page_json.to_json())
}
```

```bash
# ビルドフロー
moon run src/scripts/generate_params && moon build
```

**Node.js 等の外部ツールを使う場合:**

```bash
node scripts/generate-static-params.js && just build
```

この設計により:
- ビルド時の依存を明確にできる
- JSON Schema によるバリデーションが可能
- エディタでの補完が効く
- MoonBit コードの複雑さを低減

---

## 制約事項

### 対応しないもの

- **多段動的ルート**: `/_category_/_slug_/` のような複数の動的セグメントのネスト（一意に決定できないため）

### 将来の拡張候補

- 多段動的ルートのサポート（明示的な優先度指定付き）
- Edge Functions 対応
- Streaming SSR

---

## 実装ロードマップ

### Phase 1: 基盤整備

**目標:** 型定義と設定パーサーの実装

| タスク | 対象ファイル | 状態 |
|--------|-------------|------|
| RouteManifest 型定義 | `src/core/routes/manifest.mbt` | 部分実装 |
| ComponentRoute 追加 | `src/core/routes/manifest.mbt` | 未着手 |
| ComponentType 追加 | `src/core/routes/manifest.mbt` | 未着手 |
| page.json パーサー | `src/core/routes/page_config.mbt` | 部分実装 |
| staticParams パース | `src/core/routes/page_config.mbt` | 未着手 |
| luna.config.json パーサー | `src/core/config.mbt` | 未着手 |

**成果物:**
- `RouteManifest` 完全版
- `PageConfig` 型 (page.json 対応)
- `LunaConfig` 型 (luna.config.json 対応)

---

### Phase 2: ディレクトリスキャナー

**目標:** ファイルシステムから RouteManifest を生成

| タスク | 対象ファイル | 状態 |
|--------|-------------|------|
| moon.pkg.json 検出 | `src/astra/routes/file_router.mbt` | 未着手 |
| client/server 構造判定 | `src/astra/routes/file_router.mbt` | 未着手 |
| ComponentType 決定ロジック | `src/astra/routes/file_router.mbt` | 未着手 |
| staticParams → StaticPathEntry | `src/astra/routes/file_router.mbt` | 未着手 |
| page.json 継承マージ | `src/core/routes/merge.mbt` | 部分実装 |

**成果物:**
- `scan_pages()` 関数
- コンポーネントディレクトリの自動検出

---

### Phase 3: クライアントランタイム

**目標:** 最小限の boot + 選択的ロード機構

| タスク | 対象ファイル | 状態 |
|--------|-------------|------|
| boot/loader.js | `js/luna/src/boot/loader.ts` | 未着手 |
| boot/router.js | `js/luna/src/boot/router.ts` | 未着手 |
| hydrate/island.js | `js/luna/src/hydrate/island.ts` | 部分実装 |
| signal/runtime.js | `js/luna/src/signal/runtime.ts` | 実装済み |
| manifest.json 生成 | `src/astra/cli/build.mbt` | 未着手 |

**成果物:**
- `boot.[hash].js` (< 2KB gzip)
- `hydrate.[hash].js`
- `signal.[hash].js`
- `/_luna/manifest.json`

**詳細設計:**

```typescript
// boot/loader.ts
export class ChunkLoader {
  private loaded = new Set<string>();
  private manifest: Record<string, string[]> = {};

  async init() {
    this.manifest = await fetch('/_luna/manifest.json').then(r => r.json());
  }

  async loadForPath(path: string): Promise<void> {
    const chunks = this.manifest[path] || this.manifest['*'] || [];
    const missing = chunks.filter(c => !this.loaded.has(c));
    await Promise.all(missing.map(c => this.importChunk(c)));
  }

  private async importChunk(name: string): Promise<void> {
    await import(`/_luna/${name}.js`);
    this.loaded.add(name);
  }
}
```

```typescript
// boot/router.ts
export class MinimalRouter {
  private loader: ChunkLoader;

  constructor(loader: ChunkLoader) {
    this.loader = loader;
    this.intercept();
  }

  private intercept() {
    document.addEventListener('click', (e) => {
      const link = (e.target as Element).closest('a[href]');
      if (!link || link.origin !== location.origin) return;
      e.preventDefault();
      this.navigate(link.pathname);
    });
  }

  async navigate(path: string) {
    await this.loader.loadForPath(path);
    // 遷移処理は router-hybrid または router-spa に委譲
    window.dispatchEvent(new CustomEvent('luna:navigate', { detail: { path } }));
  }
}
```

---

### Phase 4: ビルドパイプライン

**目標:** Rolldown 統合とチャンク生成

| タスク | 対象ファイル | 状態 |
|--------|-------------|------|
| Rolldown 設定 | `rolldown.config.js` | 未着手 |
| エントリポイント解析 | `src/astra/cli/build.mbt` | 未着手 |
| チャンク依存グラフ生成 | `src/astra/builder_pool/` | 未着手 |
| manifest.json 生成 | `src/astra/cli/build.mbt` | 未着手 |
| modulepreload 挿入 | `src/astra/html/inject.mbt` | 未着手 |

**成果物:**
- `dist/_luna/*.js` チャンク群
- `dist/_luna/manifest.json`
- HTML への modulepreload 自動挿入

---

### Phase 5: SSR コンポーネント

**目標:** moon.pkg.json ディレクトリの SSR + Hydration

| タスク | 対象ファイル | 状態 |
|--------|-------------|------|
| コンポーネントスキャナー | `src/astra/routes/component_scanner.mbt` | 未着手 |
| Props シリアライズ | `src/core/serialize/props.mbt` | 未着手 |
| SSR レンダラー | `src/sol/render/ssr.mbt` | 部分実装 |
| Hydration マーカー | `src/platform/dom/client/hydrate.mbt` | 部分実装 |
| Island チャンク生成 | `src/stella/` | 部分実装 |

**成果物:**
- SSR コンポーネントの HTML 生成
- `data-island`, `data-props` 属性の出力
- Island 別チャンクの生成

---

### Phase 6: CFW デプロイ

**目標:** Cloudflare Workers への最適化デプロイ

| タスク | 対象ファイル | 状態 |
|--------|-------------|------|
| _routes.json 生成 | `src/astra/cli/build.mbt` | 未着手 |
| _worker.js 生成 | `src/astra/cli/build.mbt` | 未着手 |
| run_worker_first 判定 | `src/astra/cli/build.mbt` | 未着手 |
| ISR キャッシュ設定 | `src/astra/cli/build.mbt` | 未着手 |
| wrangler.json テンプレート | `templates/wrangler.json` | 未着手 |

**成果物:**
- CFW 向け `dist/` 構造
- 自動生成された `_routes.json`
- ISR 対応 `_worker.js`

---

### Phase 7: 拡張ルーター ✅ 完了

**目標:** Hybrid / SPA ナビゲーション

| タスク | 対象ファイル | 状態 |
|--------|-------------|------|
| HybridRouter | `js/loader/src/router/hybrid.ts` | ✅ |
| SpaRouter | `js/loader/src/router/spa.ts` | ✅ |
| prefetch 実装 | `js/loader/src/boot/router.ts` | ✅ (既存) |
| ScrollManager | `js/loader/src/router/scroll.ts` | ✅ |
| Rolldown エントリ | `rolldown.config.mjs` | ✅ |
| package.json exports | `js/loader/package.json` | ✅ |

**成果物:**
- `router/hybrid.js` (4.1KB)
- `router/spa.js` (3.8KB)
- `router/scroll.js` (3.8KB)

---

### Phase 8: Lint & DX ✅ 完了

**目標:** 開発者体験の向上

| タスク | 対象ファイル | 状態 |
|--------|-------------|------|
| orphan-client 警告 | `src/astra/cli/lint.mbt` | ✅ |
| orphan-server 通知 | `src/astra/cli/lint.mbt` | ✅ |
| missing-props 警告 | `src/astra/cli/lint.mbt` | ✅ |
| empty-static-params 警告 | `src/astra/cli/lint.mbt` | ✅ |
| page.json JSON Schema | `schemas/page.schema.json` | ✅ |
| astra.json Schema | `schemas/astra.schema.json` | ✅ |

**成果物:**
- `just lint` での警告出力
- VSCode 用 JSON Schema

---

### 依存関係

```
Phase 1 (基盤)
    │
    ▼
Phase 2 (スキャナー) ──────────────────┐
    │                                  │
    ▼                                  ▼
Phase 3 (クライアント)            Phase 5 (SSR)
    │                                  │
    ▼                                  │
Phase 4 (ビルド) ◄─────────────────────┘
    │
    ├──────────────────┐
    ▼                  ▼
Phase 6 (CFW)     Phase 7 (ルーター)
    │                  │
    └──────┬───────────┘
           ▼
      Phase 8 (DX)
```

### リスク項目

| リスク | 影響 | 対策 |
|--------|------|------|
| MoonBit ビルド時のファイル名消失 | コンポーネント特定不可 | ビルド時メタデータ生成 |
| Props シリアライズの型安全性 | 実行時エラー | JSON Schema バリデーション |
| Rolldown の安定性 | ビルド失敗 | esbuild フォールバック |
| boot サイズ超過 | パフォーマンス劣化 | サイズ監視 CI
