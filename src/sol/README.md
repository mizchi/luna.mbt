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
│   ├── layout/             # レイアウトコンポーネント
│   │   ├── moon.pkg.json
│   │   └── layout.mbt      # layout() 関数を定義
│   ├── routes/             # ルート定義
│   │   ├── moon.pkg.json
│   │   └── routes.mbt      # routes() + ページ関数を定義
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

> **Note**: 通常は `sol dev` や `sol build` が内部で自動的に呼び出すため、明示的に実行する必要はない。デバッグや生成ファイルの確認時に使用する。

```bash
sol generate                    # sol.config.json を使用 (デフォルト: dev)
sol generate --mode dev         # 開発モード (.sol/dev/ に出力)
sol generate --mode prod        # 本番モード (.sol/prod/ に出力)
sol generate --config my.json   # カスタム設定
```

生成されるファイル:
- `app/__gen__/client/exports.mbt` - hydrate 関数のエクスポート
- `app/__gen__/server/main.mbt` - サーバーエントリポイント (routes.mbt から動的生成)
- `.sol/{mode}/client/*.js` - rolldown 用 Island エントリ
- `.sol/{mode}/server/main.js` - サーバーエントリポイント (re-export)
- `.sol/{mode}/manifest.json` - rolldown programmatic API 用マニフェスト
- `.sol/{mode}/static/` - バンドル出力先

### `sol clean`

生成ファイルとキャッシュを削除。

```bash
sol clean  # .sol/, app/__gen__/, target/ を削除
```

## sol.config.json

```json
{
  "islands": ["app/client/*"],  // Island ディレクトリ (glob)
  "routes": "app/routes",       // ルート定義ディレクトリ
  "output": "app/__gen__"        // 生成出力先
}
```

## Runtime API

### アプリケーション起動

```moonbit
fn main {
  @sol.run(fn(app) {
    // ルート定義
    let app = @sol.page(app, "/", home_page, title="Home")
    let app = @sol.api(app, "/api/health", health_handler)
    @sol.serve_static(app)
  })
}
```

### ページ定義

```moonbit
// 静的ページ
pub fn about_page(ctx : @sol.Ctx) -> @luna.Node[Unit] {
  @luna.h("div", [], [@luna.vtext("About")])
}

// Island を含むページ
pub fn home_page(ctx : @sol.Ctx) -> @luna.Node[Unit] {
  let count = @signal.signal(0)
  let state_json = "{\"count\":0}"

  @luna.vfragment([
    @luna.h("h1", [], [@luna.vtext("Home")]),
    @sol.island(
      "counter",                        // Island ID
      "/static/hydrate_counter.js",     // hydrate スクリプト URL
      state_json,                       // 初期状態 JSON
      [@counter.counter(count)],        // SSR 用 VNode
    ),
  ])
}
```

### API ハンドラ

```moonbit
pub fn health_handler(ctx : @sol.Ctx) -> @js.Any {
  @sol.json_obj([("status", @core.any("ok"))])
}
```

### ページ登録オプション

```moonbit
@sol.page(app, "/",
  home_page,
  title="Home",                    // ページタイトル
  head="<style>...</style>",       // head に挿入する HTML
  hydration=true,                  // hydration 有効化
  loader_url="/static/loader.js",  // ローダー URL
)
```

## Island Architecture

### Island コンポーネント

Island は SSR と クライアントで共有されるコンポーネント:

```moonbit
// app/client/counter/counter.mbt

///| Action enum for type-safe event handling
pub enum CounterAction {
  Increment
  Decrement
} derive(Show)

///| コンポーネント関数 (SSR + クライアント共用)
pub fn counter(count : @signal.Signal[Int]) -> @luna.Node[Unit] {
  @luna.h("div", [("class", @luna.attr_static("counter"))], [
    @luna.h("span", [("class", @luna.attr_static("count-display"))], [
      @luna.vtext_sig(count),
    ]),
    @luna.h("button", [
      ("onclick", @luna.action(Increment)),
    ], [@luna.vtext("+")]),
  ])
}

///| Hydration 関数 (ローダーから呼び出される)
pub fn hydrate_counter(element : @core.Any, state : @core.Any, id : String) -> Unit {
  @dom.hydrate_island(element, state, id, fn(ctx) {
    let count = ctx.signal_int("count", 0)
    ctx.bind_actions(fn(action) {
      match action {
        "Increment" => count.set(count.get() + 1)
        "Decrement" => count.set(count.get() - 1)
        _ => ()
      }
    })
    ctx.on_update(".count-display", fn() { count.get().to_string() })
  })
}
```

### Hydration トリガー

| トリガー | 説明 | 属性値 |
|---------|------|--------|
| Load | ページロード時即座 | `load` |
| Idle | requestIdleCallback 時 | `idle` |
| Visible | IntersectionObserver 検知時 | `visible` |
| Media | メディアクエリマッチ時 | `media:query` |
| None | 手動トリガー | `none` |

```moonbit
@sol.island("counter", url, state, children, trigger=@luna.Idle)
```

### luna:* 属性

Island は以下の属性でマークアップされる:

```html
<div luna:id="counter"
     luna:url="/static/hydrate_counter.js"
     luna:state='{"count":0}'
     luna:client-trigger="load">
  <!-- SSR 済みコンテンツ -->
</div>
```

## CSR ナビゲーション

`sol-link` 属性を持つリンクは、ページ遷移時に CSR (Client-Side Rendering) で処理される:

```moonbit
// サーバーサイドで sol-link 属性付きリンクを生成
@server_dom.a(
  href="/about",
  attrs=[("sol-link", @luna.attr_static(""))],
  children=[@luna.vtext("About")],
)
```

生成される HTML:
```html
<a href="/about" sol-link>About</a>
```

クリック時の動作:
1. `sol-nav.js` がクリックをインターセプト
2. `fetch` で新しいページの HTML を取得
3. `<main id="main-content">` の内容を置換
4. History API でブラウザ履歴を更新
5. 新しいページの Island を hydrate

フルページリロードを避け、SPA ライクな UX を提供する。

## Routes 定義 (型安全ルーティング)

`@routes.Routes` を使った宣言的なルート定義:

```moonbit
// app/routes/routes.mbt

pub fn routes() -> Array[@routes.Routes] {
  [
    @routes.Island(
      path="/",
      component="home",
      url="/static/hydrate_counter.js",
      trigger=@luna.Load,
      title="Home",
      meta=[],
    ),
    @routes.Page(
      path="/about",
      component="about",
      title="About",
      meta=[],
    ),
    @routes.Get(path="/api/health", handler="health"),
  ]
}

pub fn config() -> @router.RouterConfig {
  @router.RouterConfig::default()
    .with_default_head(@layout.head())
    .with_loader_url("/static/loader.min.js")
}
```

## Streaming SSR

非同期コンテンツのストリーミング:

```moonbit
@sol.streaming_page(app, "/stream", fn(ctx) {
  @luna.vfragment([
    @luna.h("h1", [], [@luna.vtext("Loading...")]),
    @luna.vasync(async fn() {
      // 非同期データ取得
      let data = fetch_data()
      @luna.h("div", [], [@luna.vtext(data)])
    }),
  ])
})
```

## データフロー

```
[Server]                              [Client]
   │                                     │
   │  1. routes() でページ解決            │
   │  2. page() 実行、VNode 生成          │
   │  3. island() で SSR レンダリング      │
   │  4. HTML + luna:* 属性を送信  ─────────→│
   │                                     │  5. loader.js が luna:* を検知
   │                                     │  6. hydrate_*.js をロード
   │                                     │  7. hydrate_*() 実行
   │                                     │  8. イベントハンドラ接続
```

## 静的ファイル配信

```moonbit
// デフォルト設定
@sol.serve_static(app)

// カスタム設定
@sol.serve_static(app, config=@sol.StaticFileConfig::default()
  .with_mapping("custom.js", "path/to/custom.js"))
```

ファイル検索順序:
1. `static/` ディレクトリ (プロジェクトの静的ファイル)
2. `.sol/prod/static/` ディレクトリ (本番 rolldown 出力)
3. `.sol/dev/static/` ディレクトリ (開発 rolldown 出力)

## モジュール構成

```
src/sol/
├── runtime.mbt      # コア API (@sol.run, @sol.page, @sol.island 等)
├── compiler.mbt     # Rolldown バインディング
├── router/          # Hono ルーター統合
│   └── router.mbt   # @routes.Routes → Hono 変換
└── cli/             # CLI ツール
    ├── main.mbt     # エントリポイント
    ├── new.mbt      # sol new
    ├── dev.mbt      # sol dev
    ├── build.mbt    # sol build
    ├── serve.mbt    # sol serve
    ├── generate.mbt # sol generate (routes.mbt パース、コード生成)
    ├── clean.mbt    # sol clean
    └── templates.mbt # テンプレート
```

## .sol ディレクトリ構造

`sol generate` で生成されるディレクトリ構造:

```
.sol/
├── dev/                  # 開発用出力 (sol dev)
│   ├── client/           # Island エントリポイント JS
│   │   └── counter.js    # import { hydrate_counter } from '...'
│   ├── server/
│   │   └── main.js       # サーバーエントリ (re-export)
│   └── static/           # rolldown 出力 (sol dev 後)
│       └── counter.js    # バンドル済み Island
└── prod/                 # 本番用出力 (sol build)
    ├── client/
    ├── server/
    └── static/           # minify 済みバンドル
```

dev と prod を分離することで:
- 開発中は高速なインクリメンタルビルド
- 本番ビルドは独立して実行可能
- キャッシュの衝突を防止

## 参照

- [Sol Architecture v2](../../docs/sol-architecture-v2.md) - 将来の設計提案
- [Luna Core](../core/README.md) - VNode/Signal の詳細
- [Shard Architecture](../mercurius/ARCHITECTURE.md) - Island 埋め込みの仕組み
