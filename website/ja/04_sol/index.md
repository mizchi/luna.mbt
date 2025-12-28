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
- **CSRナビゲーション** - `sol-link`によるSPAライクなページ遷移
- **ミドルウェア** - Railway Oriented Programmingベースのミドルウェア
- **Server Actions** - CSRF保護付きのサーバーサイド関数
- **ネストされたレイアウト** - 階層的なレイアウト構造

## プロジェクト構造

```
myapp/
├── moon.mod.json           # MoonBitモジュール
├── package.json            # npmパッケージ
├── sol.config.json         # Sol設定
├── app/
│   ├── server/             # サーバーコンポーネント
│   │   ├── moon.pkg.json
│   │   └── routes.mbt      # routes() + config() + ページ
│   ├── client/             # クライアントコンポーネント (Islands)
│   │   └── counter/
│   │       └── counter.mbt
│   └── __gen__/            # 自動生成 (sol generate)
└── static/
    └── loader.min.js       # Islandローダー
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
sol dev              # デフォルトポート 3000
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
sol serve              # デフォルトポート 3000
sol serve --port 8080  # ポート指定
```

## SolRoutes定義

宣言的なルート定義：

```moonbit
pub fn routes() -> Array[SolRoutes] {
  [
    // ページルート
    SolRoutes::Page(
      path="/",
      handler=PageHandler(home_page),
      title="Home",
      meta=[],
    ),
    // GET APIルート
    SolRoutes::Get(
      path="/api/health",
      handler=ApiHandler(api_health),
    ),
    // ネストされたレイアウト
    SolRoutes::Layout(
      segment="admin",
      layout=admin_layout,
      children=[
        SolRoutes::Page(path="/admin", handler=PageHandler(admin_dashboard), title="Admin"),
      ],
    ),
    // ミドルウェア適用
    SolRoutes::WithMiddleware(
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

SolRoutes::WithMiddleware(
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
let submit_handler = ActionHandler(async fn(ctx) {
  let body = ctx.body
  ActionResult::ok(@js.any({ "success": true }))
})

pub fn action_registry() -> ActionRegistry {
  ActionRegistry::new(allowed_origins=["http://localhost:3000"])
    .register(ActionDef::new("submit-form", submit_handler))
}
```

### ActionResultタイプ

| タイプ | 説明 |
|--------|------|
| `Success(data)` | 成功、JSONデータを返す |
| `Redirect(url)` | 成功、リダイレクト |
| `ClientError(status, msg)` | クライアントエラー (4xx) |
| `ServerError(msg)` | サーバーエラー (5xx) |

## Islandコンポーネント

Islandはサーバーとクライアントで共有されるコンポーネント：

```moonbit
pub fn counter(count : Signal[Int]) -> @luna.Node[CounterAction] {
  div(class="counter", [
    span(class="count-display", [text_signal(count)]),
    button(onclick=@luna.action(Increment), [text("+")]),
  ])
}
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

`sol-link`属性を持つリンクはCSRで処理：

```moonbit
a(href="/about", attrs=[("sol-link", @luna.attr_static(""))], [text("About")])
```

クリック時の動作：
1. `sol-nav.js`がクリックをインターセプト
2. `fetch`で新しいページのHTMLを取得
3. `<main id="main-content">`の内容を置換
4. History APIでブラウザ履歴を更新
5. 新しいページのIslandをhydrate

## ストリーミングSSR

非同期コンテンツのストリーミング：

```moonbit
@luna.vasync(async fn() {
  let data = fetch_data().await
  div([text(data)])
})
```

## 関連項目

- [Luna UI](/ja/luna/) - コアリアクティビティの概念
- [Astra SSG](/ja/astra/) - 静的サイト生成
- [Stella](/ja/stella/) - Web Components
