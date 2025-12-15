# Sol - SSR-first Web Framework for MoonBit

Sol は MoonBit で実装された SSR-first の Web フレームワーク。
Island Architecture を採用し、サーバーサイドレンダリングとクライアントサイドの部分的ハイドレーションを組み合わせる。

## 特徴

- **Hono 統合**: 軽量な Hono をベースにしたサーバー
- **Island Architecture**: 必要な部分だけをハイドレーション
- **型安全**: MoonBit の型システムによる安全なルーティング
- **CLI ツール**: プロジェクト作成からビルドまで一貫したワークフロー
- **Streaming SSR**: 非同期コンテンツのストリーミング対応

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
1. `sol generate` - コード生成
2. `moon build` - MoonBit ビルド
3. `rolldown` - クライアントバンドル (manifest がある場合)
4. サーバー起動

```bash
sol dev              # デフォルトポート 3000
sol dev --port 8080  # ポート指定
```

### `sol build`

本番用ビルド。

```bash
sol build                 # JS ターゲット (デフォルト)
sol build --target wasm   # WASM ターゲット
sol build --skip-bundle   # rolldown スキップ
sol build --skip-generate # 生成スキップ
```

### `sol generate`

`sol.config.json` に基づいてコードを自動生成。

```bash
sol generate                    # sol.config.json を使用
sol generate --config my.json   # カスタム設定
```

生成されるファイル:
- `app/__gen__/client/exports.mbt` - hydrate 関数のエクスポート
- `app/__gen__/server/main.mbt` - サーバーエントリポイント
- `.sol/islands/*.js` - rolldown 用エントリ
- `rolldown.config.mjs` - バンドラー設定

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

### ln:* 属性

Island は以下の属性でマークアップされる:

```html
<div ln:id="counter"
     ln:url="/static/hydrate_counter.js"
     ln:state='{"count":0}'
     ln:trigger="load">
  <!-- SSR 済みコンテンツ -->
</div>
```

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
   │  4. HTML + ln:* 属性を送信  ─────────→│
   │                                     │  5. loader.js が ln:* を検知
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
1. `static/` ディレクトリ
2. `.sol/static/` ディレクトリ (rolldown 出力)

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
    ├── generate.mbt # sol generate
    └── templates.mbt # テンプレート
```

## 参照

- [Sol Architecture v2](../../docs/sol-architecture-v2.md) - 将来の設計提案
- [Luna Core](../core/README.md) - VNode/Signal の詳細
- [Shard Architecture](../renderer/shard/ARCHITECTURE.md) - Island 埋め込みの仕組み
