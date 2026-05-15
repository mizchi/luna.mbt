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
- **ドキュメント** - ドキュメントサイトは [Astra](/ja/astra/) と組み合わせる（旧 `--ssg` フラグは 0.16 で廃止）

## クイックスタート

```bash
# 1) sol ネイティブ CLI を一度だけインストール（推奨）
moon install mizchi/sol/cmd/sol            # → $MOON_HOME/bin/sol
# (代替: pnpm add -g @luna_ui/sol)

# 2) 空ディレクトリで scaffold（0.22.3+ で空ディレクトリ対応、
#    --cloudflare も 0.22.4 で空ディレクトリ対応）。--user は 5-39 文字。
sol new myapp --user yourname
cd myapp

# 3) 両方の依存をインストール。pnpm は npm 側、moon は MoonBit 側を担当。
pnpm install
moon update && moon install                # 重要 — pnpm install だけでは
                                            # MoonBit 依存は取得されない。
                                            # ここで .mooncakes/ が埋まる。

# 4) 開発サーバー起動（:7777）
pnpm dev
```

## プロジェクト構造

```
myapp/
├── moon.mod.json           # MoonBitモジュール
├── package.json            # npmパッケージ
├── sol.config.json         # Sol設定
├── app/
│   ├── server/             # サーバーコンポーネント（エントリ + ルート）
│   │   ├── moon.pkg
│   │   ├── main.mbt        # async fn main — サーバーエントリ
│   │   └── routes.mbt      # routes() + ページハンドラ（/ と /about は scaffold 済み）
│   ├── layout/             # 共通レイアウト（独立パッケージ）
│   │   ├── moon.pkg
│   │   └── layout.mbt
│   ├── client/             # クライアントコンポーネント (Islands)
│   │   ├── moon.pkg
│   │   ├── counter.mbt
│   │   └── api_tools.mbt
│   └── __gen__/            # 自動生成 (sol generate)
└── static/
    └── loader.js           # Islandローダー
```

## CLIリファレンス

### `sol new <name>`

新規プロジェクトを作成。`--user <ns>`（5-39 文字）は必須。

```bash
sol new myapp --user mizchi               # mizchi/myapp（0.22.3+ は空ディレクトリで OK）
sol new myapp --user mizchi --cloudflare  # Cloudflare Workers スターター（0.22.4+ は空ディレクトリで OK）
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

`@sol`ヘルパー関数による宣言的なルート定義：

```moonbit
pub fn routes() -> Array[@sol.SolRoutes] {
  [
    // ページルート
    @sol.route("/", home_page, title="Home"),
    // GET APIルート
    @sol.api_get("/api/health", api_health),
    // ネストされたレイアウト
    // segment="/admin" + path="/" => /admin
    @sol.wrap("/admin", admin_layout, [
      @sol.route("/", admin_dashboard, title="Admin"),
    ]),
    // ミドルウェア適用
    @sol.with_mw([@middleware.cors(), @middleware.logger()], [
      @sol.api_get("/api/data", api_data),
    ]),
  ]
}
```

### ルートヘルパー関数

| 関数 | 説明 |
|------|------|
| `@sol.route(path, handler, title=...)` | ページルート（HTMLレスポンス） |
| `@sol.api_get(path, handler)` | GET APIルート（JSONレスポンス） |
| `@sol.api_post(path, handler)` | POST APIルート（JSONレスポンス） |
| `@sol.api_put(path, handler)` | PUT APIルート（JSONレスポンス） |
| `@sol.api_delete(path, handler)` | DELETE APIルート（JSONレスポンス） |
| `@sol.wrap(segment, layout, children)` | ネストされたレイアウトグループ |
| `@sol.with_mw(middleware, children)` | ミドルウェアを適用したルートグループ |
| `@sol.nodes(content)` | ノードからsync ServerNodeを作成 |

## ミドルウェア

Railway Oriented Programmingベースのミドルウェアシステム。

### 基本的な使い方

```moonbit
let middleware = @middleware.logger()
  .then(@middleware.cors())
  .then(@middleware.security_headers())

@sol.with_mw([middleware], [
  @sol.api_get("/api/data", get_data),
])
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
pub fn config() -> @sol.RouterConfig {
  @sol.RouterConfig::default()
    .with_default_head(head())
    .with_loader_url("/static/loader.js")
    .with_streaming_ssr()
}
```

> 注: ストリーミング応答は `__LUNA_MAIN__` を含む場合 `root_template` を使い、見つからない場合は組み込み page shell にフォールバックします。

## Sol と Astra

Sol は SSR アプリケーション用フレームワークです。ドキュメント専用サイトには
[Astra](/ja/astra/) を使用してください — Sol 内蔵の `--ssg` モードは 0.16
で `mizchi/astra` として独立しました。`astra build` は同じレンダラーが
配信する全ページ URL を巡回して静的ツリーをディスクに出力するため、
「一度ビルドして任意の静的ホストに配信する」 形式が標準的なデプロイです。

SSR アプリとドキュメントを 1 バイナリで提供したい場合は、Sol のルートに並べて
Mars ミドルウェアとして Astra をマウントできます — Astra は Sol に依存しません
（`deps: mars + markdown + luna`）。

## 関連項目

- [Luna UI](/ja/luna/) - コアリアクティビティの概念
- [Astra](/ja/astra/) - Markdown 駆動の静的サイトジェネレーター
