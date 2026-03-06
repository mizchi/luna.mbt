---
title: Sol Framework
---

# Sol Framework

> **実験的**: Solは開発中です。APIは変更される可能性があります。

SolはLuna UIとMoonBitで構築されたフルスタックSSRフレームワークです。Island Architectureによるサーバーサイドレンダリングと部分的ハイドレーションを提供します。

## 特徴

- **Hono統合** - 高速で軽量なHTTPサーバー
- **Island Architecture** - スマートなトリガーで最小限のJavaScriptを配信
- **ファイルベースルーティング** - ディレクトリ構造からページとAPIルートを生成
- **型安全** - MoonBitの型がサーバーからブラウザまで流れる
- **ストリーミングSSR** - 非同期コンテンツのストリーミング対応
- **CSRナビゲーション** - `data-sol-link`によるSPAライクなページ遷移
- **ミドルウェア** - Railway Oriented Programmingベースのミドルウェア
- **Server Actions** - CSRF保護付きのサーバーサイド関数
- **ネストされたレイアウト** - 階層的なレイアウト構造
- **ドキュメント/SSG** - Sol SSG単体サイト、または`staticDirs`によるハイブリッド

## プロジェクト構造

```
myapp/
├── moon.mod.json           # MoonBitモジュール
├── package.json            # npmパッケージ
├── sol.config.json         # Sol設定
├── app/
│   ├── server/             # サーバーコンポーネント
│   │   ├── moon.pkg
│   │   └── routes.mbt      # routes() + config() + ページ
│   ├── client/             # クライアントコンポーネント (Islands)
│   │   ├── moon.pkg
│   │   └── counter.mbt
│   └── __gen__/            # 自動生成 (sol generate)
└── static/
    └── loader.js           # Islandローダー
```

## CLIリファレンス

### `sol new <name>`

新規プロジェクトを作成。

```bash
sol new myapp --user mizchi         # mizchi/myapp パッケージを作成
sol new myapp --user mizchi --dev   # ローカル luna パスを使用
```

### `sol dev`

開発サーバーを起動。以下を自動実行：
1. `sol generate --mode dev` - コード生成
2. `moon build` - MoonBitビルド
3. `rolldown` - クライアントバンドル
4. サーバー起動

```bash
sol dev              # デフォルトポート 7777
sol dev --port 8080  # ポート指定
sol dev --clean      # キャッシュクリアしてビルド
```

### `sol build`

本番用ビルド。`.sol/prod/`に出力。

```bash
sol build                 # JSターゲット (デフォルト)
sol build --target wasm   # WASMターゲット
sol build --clean         # キャッシュクリアしてビルド
```

### `sol serve`

本番ビルドを配信。`sol build`が必要。

```bash
sol serve              # デフォルトポート 7777
sol serve --port 8080  # ポート指定
```

## SolRoutes定義

宣言的なルート定義（`@router.SolRoutes`を使用）：

```moonbit
pub fn routes() -> Array[@router.SolRoutes] {
  [
    // ページルート
    @router.SolRoutes::Page(
      path="/",
      handler=@router.PageHandler(home_page),
      title="Home",
      meta=[],
      revalidate=None,
      cache=None,
    ),
    // GET APIルート
    @router.SolRoutes::Get(
      path="/api/health",
      handler=@router.ApiHandler(api_health),
    ),
    // ネストされたレイアウト
    // segment="/admin" + path="/" => /admin
    @router.SolRoutes::Layout(
      segment="/admin",
      layout=admin_layout,
      children=[
        @router.SolRoutes::Page(path="/", handler=@router.PageHandler(admin_dashboard), title="Admin", meta=[], revalidate=None, cache=None),
      ],
    ),
    // ミドルウェア適用
    @router.SolRoutes::WithMiddleware(
      middleware=[@middleware.cors(), @middleware.logger()],
      children=[...],
    ),
  ]
}
```

### SolRoutesバリアント

| バリアント | 説明 |
|-----------|------|
| `Page` | ページルート（HTMLレスポンス） |
| `Get` | GET APIルート（JSONレスポンス） |
| `Post` | POST APIルート（JSONレスポンス） |
| `Layout` | ネストされたレイアウトグループ |
| `WithMiddleware` | ミドルウェアを適用したルートグループ |

## ミドルウェア

Railway Oriented Programmingベースのミドルウェアシステム。

### 基本的な使い方

```moonbit
let middleware = @middleware.logger()
  .then(@middleware.cors())
  .then(@middleware.security_headers())

@router.SolRoutes::WithMiddleware(
  middleware=[middleware],
  children=[...],
)
```

### 組み込みミドルウェア

| ミドルウェア | 説明 |
|-------------|------|
| `logger()` | リクエストログ |
| `cors()` | CORSヘッダー |
| `csrf()` | CSRF保護 |
| `security_headers()` | セキュリティヘッダー |
| `nosniff()` | X-Content-Type-Options |
| `frame_options(value)` | X-Frame-Options |

## Server Actions

CSRF保護付きのサーバーサイド関数。

```moonbit
let submit_handler = @action.ActionHandler(async fn(ctx) {
  let body = ctx.body
  @action.ActionResult::ok(@js.any({ "success": true }))
})

pub fn action_registry() -> @action.ActionRegistry {
  @action.ActionRegistry::new(allowed_origins=["http://localhost:7777"])
    .register(@action.ActionDef::new("submit-form", submit_handler))
}
```

### ActionResultタイプ

| タイプ | 説明 |
|--------|------|
| `Success(data)` | 成功、JSONデータを返す |
| `Redirect(url)` | クライアントサイドリダイレクト（JSON形式で返す） |
| `HttpRedirect(url)` | HTTPリダイレクト（302ステータスとLocationヘッダー） |
| `ClientError(status, msg)` | クライアントエラー (4xx) |
| `ServerError(msg)` | サーバーエラー (5xx) |

## Islandコンポーネント

Islandはサーバーとクライアントで共有されるコンポーネント：

```moonbit
pub fn counter(count : @signal.Signal[Int]) -> @luna.Node[CounterAction] {
  div(class="counter", [
    span(class="count-display", [text_of(count)]),
    button(onclick=@luna.action(Increment), [text("+")]),
  ])
}
```

### Islandの埋め込み（サーバーサイド）

`ComponentRef`ベースのAPIで型安全にIslandを埋め込みます。`sol generate`がクライアントのProps型からファクトリ関数を自動生成します。

```moonbit
// 自動生成: app/__gen__/types/types.mbt
pub struct CounterProps { initial_count : Int } derive(ToJson, FromJson)
pub fn counter(props : CounterProps, trigger~ : @luna.Trigger) -> @luna.ComponentRef[CounterProps]
```

**推奨: `@sol.island()` + ComponentRef**

```moonbit
// app/server/home.mbt
let counter_props : @types.CounterProps = { initial_count: 42 }

@sol.island(
  @types.counter(counter_props),
  [div([button([text("Count: 42")])])],  // SSRフォールバック
)
```

**代替: `@server_dom.client()`（同等）**

```moonbit
@server_dom.client(
  @types.counter(counter_props),
  [div([text("Loading...")])],
)
```

**低レベル: `@sol.island_raw()`（文字列ベース、非推奨）**

```moonbit
@sol.island_raw("counter", "/static/counter.js", props_json, children)
```

### Hydrationトリガー

| トリガー | 説明 |
|---------|------|
| `Load` | ページロード時即座 |
| `Idle` | requestIdleCallback時 |
| `Visible` | IntersectionObserver検知時 |
| `Media(query)` | メディアクエリマッチ時 |
| `None` | 手動トリガー |

## CSRナビゲーション

`data-sol-link`属性を持つリンクはCSRで処理されます。`sol_link`ヘルパを使用：

```moonbit
sol_link(href="/about", [text("About")])
```

クリック時の動作：
1. `sol-nav.js`がクリックをインターセプト
2. `fetch`で新しいページのHTMLを取得
3. `<main id="main-content">`の内容を置換
4. History APIでブラウザ履歴を更新
5. 新しいページのIslandをhydrate

## ストリーミングSSR

`ServerNode::async_`を使用した非同期コンテンツのストリーミング：

```moonbit
@server_dom.ServerNode::async_(async fn() {
  let data = fetch_data()  // 非同期関数呼び出し
  div([text(data)])
})
```

`register_sol_routes` でストリーミング応答を使う場合は、`RouterConfig` で有効化します（デフォルトは無効）。

```moonbit
pub fn config() -> @router.RouterConfig {
  @router.RouterConfig::default()
    .with_default_head(head())
    .with_loader_url("/static/loader.js")
    .with_streaming_ssr()
}
```

> 注: ストリーミング応答は `__LUNA_MAIN__` を含む場合 `root_template` を使い、見つからない場合は組み込み page shell にフォールバックします。

## モード

Solは3つの使い方を想定しています。

### アプリ (デフォルト)

- Islands付きSSRアプリ
- `moon.mod.json`が必要
- `sol dev`でアプリサーバー起動

### SSGのみ（ドキュメント）

`sol.config.json`に`ssg`または`docs`セクションがあり、かつ`moon.mod.json`が無い場合に検出されます。

```bash
sol new my-docs --ssg
sol dev    # HMR付きSSG開発サーバー
sol build  # 静的サイト生成
sol lint   # SSGコンテンツをリント
```

SSG固有の機能と設定については、[Sol SSG](/ja/sol/ssg/)を参照してください。

### ハイブリッド（アプリ + ドキュメント）

アプリを維持したまま、`staticDirs`でドキュメントをマウントします：

```json
{
  "staticDirs": [
    { "path_prefix": "/docs", "source_dir": "docs", "title": "Docs" }
  ]
}
```

- `sol build`でアプリとドキュメントをまとめてビルド
- `sol dev`はアプリサーバーを起動（ドキュメントのプレビューは`sol dev --mode ssg`）

## 関連項目

- [Luna UI](/ja/luna/) - コアリアクティビティの概念
- [Sol SSG](/ja/sol/ssg/) - 静的サイト生成（Sol CLI経由で実行）
