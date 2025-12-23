# Sol - SSR-first Web Framework for MoonBit

Sol は MoonBit で実装された SSR-first の Web フレームワーク。
Island Architecture を採用し、サーバーサイドレンダリングとクライアントサイドの部分的ハイドレーションを組み合わせる。

## Playground

`examples/sol_app/` は Sol フレームワークの開発用 playground。
新機能の試作、統合テスト、実装の検証に使用する。

```bash
# Playground で開発サーバーを起動
cd examples/sol_app
npm install
just sol dev
```

## 特徴

- **Hono 統合**: 軽量な Hono をベースにしたサーバー
- **Island Architecture**: 必要な部分だけをハイドレーション
- **型安全**: MoonBit の型システムによる安全なルーティング
- **CLI ツール**: プロジェクト作成からビルドまで一貫したワークフロー
- **Streaming SSR**: 非同期コンテンツのストリーミング対応
- **CSR ナビゲーション**: `sol-link` 属性による SPA ライクなページ遷移
- **Middleware**: Railway Oriented Programming ベースのミドルウェアシステム
- **Server Actions**: CSRF 保護付きのサーバーサイド関数
- **Nested Layouts**: 階層的なレイアウト構造のサポート

## クイックスタート

```bash
# 新規プロジェクト作成
sol new myapp --user yourname
cd myapp

# 依存関係インストール
npm install

# 開発サーバー起動
npm run dev
```

## プロジェクト構造

`sol new` で生成されるプロジェクト構造:

```
myapp/
├── moon.mod.json           # MoonBit モジュール定義
├── package.json            # npm パッケージ定義
├── sol.config.json         # Sol 設定ファイル
├── app/
│   ├── server/             # サーバーコンポーネント
│   │   ├── moon.pkg.json
│   │   └── routes.mbt      # routes() + config() + ページ関数
│   ├── client/             # クライアントコンポーネント (Islands)
│   │   └── counter/
│   │       ├── moon.pkg.json
│   │       └── counter.mbt # render + hydrate 関数
│   └── __gen__/            # 自動生成 (sol generate)
│       ├── client/         # クライアントエクスポート
│       └── server/         # サーバーエントリポイント
└── static/
    └── loader.min.js       # Island ローダー
```

## CLI コマンド

### `sol new <name> --user <namespace>`

新規プロジェクトを作成。

```bash
sol new myapp --user mizchi         # mizchi/myapp パッケージを作成
sol new myapp --user mizchi --dev   # ローカル luna パスを使用 (開発用)
```

### `sol dev`

開発サーバーを起動。以下を自動実行:
1. `sol generate --mode dev` - コード生成 (`.sol/dev/` に出力)
2. `moon build` - MoonBit ビルド
3. `rolldown` - クライアントバンドル (manifest がある場合)
4. サーバー起動

```bash
sol dev              # デフォルトポート 3000
sol dev --port 8080  # ポート指定
sol dev --clean      # キャッシュをクリアしてビルド
```

### `sol build`

本番用ビルド。`.sol/prod/` に出力。

```bash
sol build                 # JS ターゲット (デフォルト)
sol build --target wasm   # WASM ターゲット
sol build --skip-bundle   # rolldown スキップ
sol build --skip-generate # 生成スキップ
sol build --clean         # キャッシュをクリアしてビルド
```

### `sol serve`

本番ビルドを配信。事前に `sol build` でビルドが必要。

```bash
sol serve              # デフォルトポート 3000
sol serve --port 8080  # ポート指定
```

### `sol generate`

`sol.config.json` に基づいてコードを自動生成。

> **Note**: 通常は `sol dev` や `sol build` が内部で自動的に呼び出すため、明示的に実行する必要はない。

```bash
sol generate                    # sol.config.json を使用 (デフォルト: dev)
sol generate --mode dev         # 開発モード (.sol/dev/ に出力)
sol generate --mode prod        # 本番モード (.sol/prod/ に出力)
```

### `sol clean`

生成ファイルとキャッシュを削除。

```bash
sol clean  # .sol/, app/__gen__/, target/ を削除
```

## SolRoutes 定義

`SolRoutes` を使った宣言的なルート定義:

```moonbit
// app/server/routes.mbt

pub fn routes() -> Array[SolRoutes] {
  [
    // ページルート
    SolRoutes::Page(
      path="/",
      handler=PageHandler(home_page),
      title="Home",
      meta=[],
    ),
    // API ルート (GET)
    SolRoutes::Get(
      path="/api/health",
      handler=ApiHandler(api_health),
    ),
    // API ルート (POST)
    SolRoutes::Post(
      path="/api/submit",
      handler=ApiHandler(api_submit),
    ),
    // ネストされたレイアウト
    SolRoutes::Layout(
      segment="admin",
      layout=admin_layout,
      children=[
        SolRoutes::Page(path="/admin", handler=PageHandler(admin_dashboard), title="Admin"),
        SolRoutes::Page(path="/admin/users", handler=PageHandler(admin_users), title="Users"),
      ],
    ),
    // ミドルウェア適用
    SolRoutes::WithMiddleware(
      middleware=[@middleware.cors(), @middleware.logger()],
      children=[
        SolRoutes::Get(path="/api/data", handler=ApiHandler(api_data)),
      ],
    ),
  ]
}

pub fn config() -> RouterConfig {
  RouterConfig::default()
    .with_default_head(head())
    .with_loader_url("/static/loader.min.js")
}
```

### SolRoutes バリアント

| バリアント | 説明 |
|-----------|------|
| `Page` | ページルート (HTML レスポンス) |
| `Get` | GET API ルート (JSON レスポンス) |
| `Post` | POST API ルート (JSON レスポンス) |
| `Layout` | ネストされたレイアウトグループ |
| `WithMiddleware` | ミドルウェアを適用したルートグループ |

## Nested Layouts

階層的なレイアウト構造をサポート:

```moonbit
// Admin セクションのレイアウト
fn admin_layout(
  props : PageProps,
  content : ServerNode,
) -> ServerNode raise {
  ServerNode::sync(@luna.fragment([
    h1([text("Admin Panel")]),
    nav([
      a(href="/admin", attrs=[("sol-link", @luna.attr_static(""))], [text("Dashboard")]),
      a(href="/admin/users", attrs=[("sol-link", @luna.attr_static(""))], [text("Users")]),
    ]),
    div(class="admin-content", [content.to_vnode()]),
  ]))
}

// ルート定義
SolRoutes::Layout(
  segment="admin",     // URL プレフィックス
  layout=admin_layout, // レイアウト関数
  children=[
    // /admin
    SolRoutes::Page(path="/admin", handler=PageHandler(admin_dashboard), title="Admin"),
    // /admin/users
    SolRoutes::Page(path="/admin/users", handler=PageHandler(admin_users), title="Users"),
  ],
)
```

## Middleware

Railway Oriented Programming ベースのミドルウェアシステム。

### 基本的な使い方

```moonbit
// ミドルウェアの合成
let middleware = @middleware.logger()
  .then(@middleware.cors())
  .then(@middleware.security_headers())

// ルートに適用
SolRoutes::WithMiddleware(
  middleware=[middleware],
  children=[...],
)
```

### 組み込みミドルウェア

| ミドルウェア | 説明 |
|-------------|------|
| `logger()` | リクエストログ |
| `cors()` | CORS ヘッダー |
| `csrf()` | CSRF 保護 |
| `security_headers()` | セキュリティヘッダー |
| `nosniff()` | X-Content-Type-Options |
| `frame_options(value)` | X-Frame-Options |

### CORS 設定

```moonbit
@middleware.cors_with_config(
  CorsConfig::default()
    .with_origin_single("https://example.com")
    .with_methods(["GET", "POST"])
    .with_credentials()
)
```

### Security Headers

```moonbit
@middleware.security_headers_with_config(
  SecurityHeadersConfig::default()
    .with_csp("default-src 'self'")
    .with_frame_options("DENY")
)
```

### ミドルウェア合成

```moonbit
// 順次実行 (m1 → m2)
let combined = @middleware.then_(m1, m2)
// または
let combined = m1.then(m2)

// 配列から合成
let pipeline = @middleware.pipeline([m1, m2, m3])

// 条件付き実行
let conditional = @middleware.when(
  fn(ctx) { ctx.request.method == "POST" },
  csrf_middleware,
)
```

## Server Actions

CSRF 保護付きのサーバーサイド関数。詳細は [Server Actions README](./action/README.md) を参照。

### 基本的な使い方

```moonbit
// アクションハンドラを定義
let submit_handler = ActionHandler(async fn(ctx) {
  let body = ctx.body
  // ... 処理
  ActionResult::ok(@js.any({ "success": true }))
})

// レジストリに登録
pub fn action_registry() -> ActionRegistry {
  ActionRegistry::new(allowed_origins=["http://localhost:3000"])
    .register(ActionDef::new("submit-form", submit_handler))
}
```

### ActionResult タイプ

| タイプ | 説明 |
|--------|------|
| `Success(data)` | 成功、JSON データを返す |
| `Redirect(url)` | 成功、リダイレクト |
| `ClientError(status, msg)` | クライアントエラー (4xx) |
| `ServerError(msg)` | サーバーエラー (5xx) |

## Island Architecture

### Island コンポーネント

Island は SSR と クライアントで共有されるコンポーネント:

```moonbit
// app/client/counter/counter.mbt

pub fn counter(count : Signal[Int]) -> @luna.Node[CounterAction] {
  div(class="counter", [
    span(class="count-display", [text_signal(count)]),
    button(onclick=@luna.action(Increment), [text("+")]),
    button(onclick=@luna.action(Decrement), [text("-")]),
  ])
}
```

### Hydration トリガー

| トリガー | 説明 |
|---------|------|
| `Load` | ページロード時即座 |
| `Idle` | requestIdleCallback 時 |
| `Visible` | IntersectionObserver 検知時 |
| `Media(query)` | メディアクエリマッチ時 |
| `None` | 手動トリガー |

## CSR ナビゲーション

`sol-link` 属性を持つリンクは CSR で処理される:

```moonbit
a(href="/about", attrs=[("sol-link", @luna.attr_static(""))], [text("About")])
```

クリック時の動作:
1. `sol-nav.js` がクリックをインターセプト
2. `fetch` で新しいページの HTML を取得
3. `<main id="main-content">` の内容を置換
4. History API でブラウザ履歴を更新
5. 新しいページの Island を hydrate

## Streaming SSR

非同期コンテンツのストリーミング:

```moonbit
@luna.vasync(async fn() {
  let data = fetch_data().await
  div([text(data)])
})
```

## モジュール構成

```
src/sol/
├── runtime.mbt      # コア API
├── compiler.mbt     # Rolldown バインディング
├── router/          # Hono ルーター統合
│   ├── router.mbt   # ルート登録
│   ├── sol_routes.mbt # SolRoutes 定義
│   └── fragment.mbt # フラグメントレスポンス (CSR)
├── middleware/      # ミドルウェアシステム
│   ├── types.mbt    # MwContext, MwRequest, MwResponse
│   ├── compose.mbt  # 合成関数 (then, pipeline)
│   ├── logger.mbt   # Logger ミドルウェア
│   ├── cors.mbt     # CORS ミドルウェア
│   ├── csrf.mbt     # CSRF ミドルウェア
│   └── security_headers.mbt # セキュリティヘッダー
├── action/          # Server Actions
│   ├── action.mbt   # ActionHandler, ActionResult
│   └── router.mbt   # register_actions
└── cli/             # CLI ツール
    ├── main.mbt     # エントリポイント
    ├── new.mbt      # sol new
    ├── dev.mbt      # sol dev
    ├── build.mbt    # sol build
    ├── serve.mbt    # sol serve
    ├── generate.mbt # sol generate
    └── clean.mbt    # sol clean
```

## 参照

- [Server Actions](./action/README.md) - Server Actions の詳細
- [Luna Core](../luna/README.md) - VNode/Signal の詳細
- [Stella](../stella/README.md) - Island 埋め込みの仕組み
