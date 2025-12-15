# Sol Architecture v2

> **ステータス: 設計提案 (Draft)**
>
> このドキュメントは Sol の将来の設計提案です。
> 現在の実装については [src/sol/README.md](../src/sol/README.md) を参照してください。
>
> 主な違い:
> - v2 提案: `app/client/` と `app/server/` の明確な分離
> - 現在の実装: `app/routes/` にルートとページを統合

## 概要

Sol は MoonBit で実装された Next.js 風の SSR-first Web フレームワーク。
Island Architecture を採用し、サーバーコンポーネントとクライアントコンポーネントを明確に分離する。

## 設計原則

1. **Server-first**: サーバーコンポーネントがデフォルト、クライアントは明示的に指定
2. **型安全な境界**: server/client 間の型混在を防ぐ
3. **明示的なデータフロー**: Props はサーバーからクライアントへ一方向

## ディレクトリ構造

```
app/
├── client/                   # クライアントコンポーネント（フラット配置）
│   ├── counter.mbt           # pub fn counter(props: CounterProps) -> @luna.Node[Unit]
│   └── toggle.mbt            # 他のコンポーネント
├── server/                   # サーバーコンポーネント
│   ├── routes.mbt            # pub fn routes() + config()
│   ├── layout.mbt            # async fn layout(...) -> @server_dom.Node
│   ├── home.mbt              # async fn home(PageProps) -> @server_dom.Node
│   └── about.mbt             # async fn about(PageProps) -> @server_dom.Node
└── _gen/                     # sol generate で自動生成
    ├── client/
    │   ├── router.mbt        # CSRルーター
    │   └── hydrate_*.mbt     # 各コンポーネントのhydration関数
    └── server/
        └── main.mbt          # サーバーエントリポイント
```

## 依存関係

```
server/ ──import──→ client/  ✓ OK（型も含めて読み込み可能）
client/ ──import──→ server/  ✗ NG（禁止）
```

## 型の分離

| モジュール | 用途 | イベントハンドラ |
|-----------|------|-----------------|
| `@server_dom.Node` | サーバーサイドレンダリング | なし |
| `@luna.Node[Unit]` | クライアントコンポーネント | あり |

- `island()` を経由しないと、client側の dom をサーバーに埋め込めない
- 型システムにより、server/client の混在を防止

## コンポーネント定義

### クライアントコンポーネント

```moonbit
// app/client/counter.mbt

pub enum CounterAction {
  Increment
  Decrement
} derive(Show)

pub(all) struct CounterProps {
  initial_count: Int
}

pub fn counter(props: CounterProps) -> @luna.Node[Unit] {
  let count = @signal.signal(props.initial_count)
  @luna.h("div", [("class", @luna.attr_static("counter"))], [
    @luna.h("span", [("class", @luna.attr_static("count-display"))], [
      @luna.vtext_sig(count),
    ]),
    @luna.h("div", [("class", @luna.attr_static("buttons"))], [
      @luna.h("button", [
        ("class", @luna.attr_static("dec")),
        ("onclick", @luna.action(Decrement)),
      ], [@luna.vtext("-")]),
      @luna.h("button", [
        ("class", @luna.attr_static("inc")),
        ("onclick", @luna.action(Increment)),
      ], [@luna.vtext("+")]),
    ]),
  ])
}
```

- Props はサーバーから渡される
- hydration 関数はユーザーが書かない（`sol generate` で自動生成）

### サーバーコンポーネント

```moonbit
// app/server/layout.mbt

pub async fn layout(children: Array[@server_dom.Node]) -> @server_dom.Node {
  @server_dom.html([
    @server_dom.head([
      @server_dom.title("My App"),
      @server_dom.meta([("charset", "utf-8")]),
    ]),
    @server_dom.body([
      @server_dom.div([("id", "__root__")], children),
    ]),
  ])
}
```

```moonbit
// app/server/home.mbt

pub async fn home(_props: @router.PageProps) -> @server_dom.Node {
  // island() でクライアントコンポーネントを埋め込み
  // 1. SSR レンダリング
  // 2. ln:* 属性付与（hydration情報）
  // 3. @server_dom.Node として返却
  @sol.island(
    component=@client.counter,
    props={ initial_count: 0 },
    trigger=@luna.Load,
  )
}
```

### ルート定義

```moonbit
// app/server/routes.mbt

pub fn routes() -> Array[@routes.Routes] {
  [
    @routes.Page(
      path="/",
      component=home,
      title="Home",
      meta=[],
    ),
    @routes.Page(
      path="/about",
      component=about,
      title="About",
      meta=[],
    ),
    @routes.Get(path="/api/health", handler=health),
  ]
}

pub fn config() -> @router.RouterConfig {
  @router.RouterConfig::default()
    .with_loader_url("/static/loader.min.js")
}
```

## island() 関数の動作

`island()` は server/client 境界を越える唯一の方法：

```moonbit
@sol.island(
  component=@client.counter,    // クライアントコンポーネント関数
  props={ initial_count: 0 },   // サーバーからクライアントへ渡すProps
  trigger=@luna.Load,           // hydration トリガー
)
```

内部動作：
1. `@client.counter(props)` を呼び出し、`@luna.Node[Unit]` を取得
2. VNode を HTML 文字列にレンダリング（SSR）
3. `ln:*` 属性を付与（`ln:id`, `ln:url`, `ln:state`, `ln:trigger`）
4. `@server_dom.Node` として返却

## sol generate の役割

`sol generate` コマンドは以下を自動生成：

### 1. Hydration 関数 (`app/_gen/client/hydrate_*.mbt`)

```moonbit
// app/_gen/client/hydrate_counter.mbt (AUTO-GENERATED)

pub fn hydrate_counter(element: @core.Any, state: @core.Any, id: String) -> Unit {
  @dom.hydrate_island(element, state, id, fn(ctx) {
    let props = ctx.parse_props(CounterProps::from_json)
    let count = ctx.signal_int("count", props.initial_count)
    ctx.bind_actions(fn(action) {
      match action {
        "increment" => count.set(count.get() + 1)
        "decrement" => count.set(count.get() - 1)
        _ => ()
      }
    })
    ctx.on_update(".count-display", fn() { count.get().to_string() })
  })
}
```

### 2. CSR ルーター (`app/_gen/client/router.mbt`)

```moonbit
// app/_gen/client/router.mbt (AUTO-GENERATED)

pub fn init_router() -> Unit {
  let routes = @app_routes.routes()
  @sol_client.setup_navigation(routes)
}
```

### 3. サーバーエントリポイント (`app/_gen/server/main.mbt`)

```moonbit
// app/_gen/server/main.mbt (AUTO-GENERATED)

pub async fn main {
  let app = @sol.create_app()
  let routes = @app_routes.routes()
  let config = @app_routes.config()
  @sol.register_routes(app, routes, config)
  @sol.start(app)
}
```

## Hydration トリガー

| トリガー | 説明 |
|---------|------|
| `@luna.Load` | ページロード時即座 |
| `@luna.Idle` | `requestIdleCallback` 時 |
| `@luna.Visible` | `IntersectionObserver` 検知時 |
| `@luna.Media(query)` | メディアクエリマッチ時 |
| `@luna.None` | 手動トリガー |

## データフロー

```
[Server]                              [Client]
   │                                     │
   │  1. routes() でページ解決            │
   │  2. home() 実行                     │
   │  3. island() で SSR                 │
   │  4. HTML + ln:* 属性を送信  ────────→│
   │                                     │  5. loader.js が ln:* を検知
   │                                     │  6. hydrate_counter.js をロード
   │                                     │  7. hydrate_counter() 実行
   │                                     │  8. イベントハンドラ接続
```

## 将来の拡張

- **Loader/Action パターン**: Remix 風のデータフェッチ
- **Streaming SSR**: 部分的なストリーミングレンダリング
- **Route prefetch**: マウスホバー時の先読み
- **Nested layouts**: レイアウトの階層化
