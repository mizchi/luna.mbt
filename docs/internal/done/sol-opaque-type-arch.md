# Sol Opaque Type Architecture

サーバーとクライアントを疎結合にしつつ、型安全なIsland埋め込みを実現する設計。

## 背景と問題

現状の問題：
- サーバーがクライアントの型を直接知らないとレンダリングできない
- `@routes.WcIsland` で `component="wc_counter"` のように文字列で指定している
- 型安全性がない

## 設計概要

### 1. ComponentRef[T] 型

`@luna` (core) に定義する Opaque 型。クライアントコンポーネントへの参照を表す。

```moonbit
// src/core/vnode.mbt に追加

pub struct ComponentRef[T] {
  url: String      // クライアントJSのパス (e.g., "/static/counter.js")
  props: T         // Props (ToJson制約)
  wc: Bool         // Web Components かどうか
  trigger: Trigger // Hydration トリガー
}
```

### 2. Node[E] に InternalRef variant 追加

```moonbit
pub enum Node[E] {
  Element(...)
  Text(String)
  Fragment(Array[Node[E]])
  // 新規追加
  InternalRef(
    url: String,
    state: String,    // JSON シリアライズされた props
    trigger: Trigger,
    wc: Bool,
    children: Array[Node[E]]  // SSR用静的コンテンツ
  )
}
```

### 3. 生成される types.mbt

`app/__gen__/types/types.mbt` に生成されるコード：

```moonbit
// Props 構造体（既存）
pub struct CounterProps {
  initial_count: Int
} derive(ToJson, FromJson)

pub struct WcCounterProps {
  initial_count: Int
} derive(ToJson, FromJson)

// ComponentRef を返す関数（新規生成）
pub fn counter(props: CounterProps, trigger~: @luna.Trigger = @luna.Load) -> @luna.ComponentRef[CounterProps] {
  { url: "/static/counter.js", props, wc: false, trigger }
}

pub fn wc_counter(props: WcCounterProps, trigger~: @luna.Trigger = @luna.Load) -> @luna.ComponentRef[WcCounterProps] {
  { url: "/static/wc_counter.js", props, wc: true, trigger }
}
```

### 4. server_dom.island() 関数

`ComponentRef[T]` を `Node[Unit]` に変換する関数。サーバーコンポーネントでは必ずこれを経由する。

```moonbit
// src/platform/server_dom/island.mbt

pub fn island[T: ToJson](
  ref: @luna.ComponentRef[T],
  children~: Array[@luna.Node[Unit]] = []
) -> @luna.Node[Unit] {
  @luna.Node::InternalRef(
    ref.url,
    ref.props.to_json().stringify(),
    ref.trigger,
    ref.wc,
    children,
  )
}
```

children は SSR 用の静的コンテンツ。サーバーで生成したコンテンツをクライアントが変更する方法はない。

### 5. routes.mbt の変更

`WcIsland` は Routes から削除。すべて `Page` で定義する。

```moonbit
// Before
@routes.WcIsland(
  path="/wc-counter",
  component="wc_counter",
  title="WC Counter",
  meta=[],
),

// After
@routes.Page(
  path="/wc-counter",
  component="wc_counter",
  title="WC Counter",
  meta=[],
),
```

### 6. サーバーコンポーネントでの使用例

```moonbit
// app/server/wc_counter.mbt

pub fn wc_counter(props: @router.PageProps) -> @server_dom.ServerNode {
  // 型安全に props を作成
  let counter_props: @types.WcCounterProps = { initial_count: 42 }

  let content = [
    h1(children=[text("WC Counter")]),
    p(children=[text("Web Components based counter")]),
    // 型安全な island 埋め込み
    @server_dom.island(
      @types.wc_counter(counter_props),
      children=[
        // SSR 用静的コンテンツ
        div(class="counter", children=[
          span(class="count-display", children=[text("42")]),
        ]),
      ],
    ),
  ]

  @server_dom.ServerNode::sync(layout(content))
}
```

## レンダリングフロー

```
1. サーバーコンポーネント
   @types.wc_counter(props) -> ComponentRef[WcCounterProps]

2. island() で変換
   @server_dom.island(ref, children) -> Node[Unit]::InternalRef(...)

3. server_dom でレンダリング
   InternalRef -> <wc-counter luna:url="..." luna:state="..." luna:client-trigger="...">
                    <template shadowrootmode="open">...</template>
                  </wc-counter>

4. クライアントで Hydration
   luna:url のスクリプトをロード -> コンポーネント初期化
```

## 生成の責務

### src/sol/cli/generate.mbt

現在生成しているもの：
- `app/__gen__/types/types.mbt` - Props 構造体

追加で生成するもの：
- Props に対応する `ComponentRef` を返す関数

### src/sol/mbti_utils.mbt

`.mbti` ファイルをパースして：
- クライアントコンポーネントの Props 型を抽出
- 対応する URL パスを計算

## Routes 型の変更

```moonbit
// src/core/routes/routes.mbt

pub enum Routes {
  Page(path: String, component: String, title: String, meta: Array[(String, String)])
  Island(...)   // 既存（将来的に削除検討）
  // WcIsland は削除
  Param(...)
  Layout(...)
  Group(...)
  Get(...)
  Post(...)
}
```

## 利点

1. **型安全性**: `ComponentRef[T]` により Props の型が保証される
2. **疎結合**: サーバーはクライアントの実装詳細を知らない
3. **プラットフォーム中立**: `ComponentRef[T]` は DOM に依存しない
4. **明示的な境界**: `island()` を経由することで Server/Client の境界が明確

## 将来の拡張

- Native 対応: `InternalRef` を別の形式に展開可能
- React/Preact Bridge: `ComponentRef` から React コンポーネントへの変換
- 型安全な Route Params: Page path のパラメータを分解して型安全な params を生成
  ```moonbit
  // 将来的な構想
  // path="/users/:id" から自動生成
  pub struct UsersIdParams {
    id: String
  }
  pub fn users_page(props: PageProps[UsersIdParams]) -> ServerNode
  ```
