---
title: Islands API
---

# Islands API

部分ハイドレーションのための、サーバーサイド Island 描画。

## island(ComponentRef ベース、推奨)

型安全な `ComponentRef` を使って Island 要素を作ります。ファクトリ関数はクライアント側の Props 型から `sol generate` が自動生成します。

```moonbit
// 自動生成: app/__gen__/types/types.mbt
pub struct CounterProps { initial_count : Int } derive(ToJson, FromJson)
pub fn counter(props : CounterProps, trigger~ : @luna.Trigger) -> @luna.ComponentRef[CounterProps]
```

```moonbit
// サーバー側での利用
let counter_props : @types.CounterProps = { initial_count: 42 }

@sol.island(
  @types.counter(counter_props),
  [div([button([text("Count: 42")])])],
)
```

### シグネチャ

```moonbit
fn[T : ToJson, E] island(
  cref : @luna.ComponentRef[T],
  children : Array[@luna.Node[E, String]],
) -> @luna.Node[E, String]
```

### 引数

| 引数 | 型 | 説明 |
|------|----|------|
| `cref` | `ComponentRef[T]` | 型安全なコンポーネント参照(生成されたファクトリから) |
| `children` | `Array[Node]` | サーバー描画されるフォールバック内容 |

### island_with

子要素の配列ではなく描画関数を受け取る版:

```moonbit
@sol.island_with(
  @types.counter(counter_props),
  fn() { div([button([text("Count: 42")])]) },
)
```

### 代替: @server_dom.client()

Luna の static DOM パッケージが提供する同等の API:

```moonbit
@server_dom.client(
  @types.counter(counter_props),
  [div([text("Loading...")])],
)
```

`styles?` を渡すとシャドウルート用のスコープ付き CSS を指定できます。

## island_raw(文字列ベース、低レベル)

生の文字列引数で Web Components Island を作ります。内部では `@luna.wc_island` に委譲し、`island()` と同じ `<wc-*>` markup を出力します。型安全性のため、通常は `ComponentRef` を使う `island()` を選んでください。

```moonbit
@sol.island_raw(
  "wc-counter",
  "/components/counter.js",
  initial.to_string(),
  [@element.div([@element.button([@element.text("Count: \{initial}")])])],
  trigger=@luna.Trigger::Load,
)
```

### シグネチャ

```moonbit
fn[E] island_raw(
  String,                          // name
  String,                          // url
  String,                          // state
  Array[@luna.Node[E, String]],    // children
  trigger? : @luna.Trigger,
) -> @luna.Node[E, String]
```

### 引数

| 引数 | 型 | 説明 |
|------|----|------|
| `name` | `String` | カスタム要素のタグ名(例 `"wc-counter"`) |
| `url` | `String` | JavaScript モジュールの URL |
| `state` | `String` | シリアライズされた props(JSON) |
| `children` | `Array[Node]` | サーバー描画される内容 |
| `trigger?` | `Trigger` | ハイドレーションの契機(既定: `Load`) |

### HTML 出力

```html
<wc-counter
  luna:wc-url="/components/counter.js"
  luna:wc-state="0"
  luna:wc-trigger="load"
>
  <div><button>Count: 0</button></div>
</wc-counter>
```

### Visible トリガーの例

```moonbit
// 遅延読み込み Island — スクロールで表示されたときにハイドレート
@sol.island(
  @types.lazy({}, trigger=@luna.Trigger::Visible),
  [@element.text("Lazy content")],
)
// 出力: luna:wc-trigger="visible"
```

## Trigger

ハイドレーションのタイミングを表す enum です。

```moonbit
enum Trigger {
  Load           // ページ読み込み直後
  Idle           // ブラウザがアイドルのとき
  Visible        // 要素がビューポートに入ったとき
  Media(String)  // メディアクエリが一致したとき
  None           // 手動トリガーのみ
}
```

`@luna` はこの型を `@core.TriggerType` から `Trigger` という名前で再エクスポートしています。値は型を経由して `@luna.Trigger::Load` のように書きます(`@luna.Load` では解決できません)。

### 値

| 値 | HTML 出力 | 説明 |
|----|-----------|------|
| `@luna.Trigger::Load` | `load` | 即座にハイドレート |
| `@luna.Trigger::Idle` | `idle` | `requestIdleCallback` |
| `@luna.Trigger::Visible` | `visible` | `IntersectionObserver` |
| `@luna.Trigger::Media(query)` | `media:(query)` | メディアクエリ一致 |
| `@luna.Trigger::None` | `none` | `__LUNA_HYDRATE__` による手動 |

### 例

```moonbit
// 即座(既定)
trigger=@luna.Trigger::Load

// ブラウザのアイドル時
trigger=@luna.Trigger::Idle

// スクロールで表示されたとき
trigger=@luna.Trigger::Visible

// デスクトップのみ
trigger=@luna.Trigger::Media("(min-width: 768px)")

// 手動トリガー
trigger=@luna.Trigger::None
```

## render_with_preloads

描画しつつ、preload 用の Island URL を集めます。

```moonbit
let node = @element.div([
  @sol.island(@types.component_a({}), [@element.text("A")]),
  @sol.island(@types.component_b({}), [@element.text("B")]),
])

let result = render_with_preloads(node)
// result.html      描画された HTML
// result.preload_urls = ["/static/component_a.js", "/static/component_b.js"]
```

### preload リンクの生成

```moonbit
let preload_links = result.preload_urls.map(fn(url) {
  @server_dom.link(rel="modulepreload", href=url)
})
```

## Web Components Island(低レベル)

`@sol.island()` は既に Web Component の markup を出力します。以下は同じ仕組みへの直接の入り口で、タグ名やスコープ付きスタイルを完全に制御したい場合や、`ComponentRef` の配線を省きたい場合に使います。

### wc_island_raw / @luna.wc_island

文字列ベースで直接 Web Component Island を作るには `@luna.wc_island` か `@sol.wc_island_raw` を使います:

```moonbit
@luna.wc_island(
  "wc-counter",                        // name
  "/static/wc-counter.js",             // url
  ":host { display: block; }",         // styles
  initial.to_string(),                 // state
  [@server_dom.button([@server_dom.text("Count: \{initial}")])],
  trigger=@luna.Trigger::Load,
)
```

### 引数(`@luna.wc_island`)

最初の 5 つは**この順の位置引数**です。名前付きなのは `trigger` だけです。

| # | 引数 | 型 | 説明 |
|---|------|----|------|
| 1 | `name` | `String` | カスタム要素のタグ名 |
| 2 | `url` | `String` | JavaScript モジュールの URL |
| 3 | `styles` | `String` | シャドウルート用のスコープ付き CSS |
| 4 | `state` | `String` | シリアライズされた props(JSON) |
| 5 | `children` | `Array[Node[E, A]]` | サーバー描画される内容 |
| — | `trigger?` | `Trigger` | ハイドレーションの契機(既定 `Load`) |

`@server_dom.wc_island` は同じものを SSR 向けに扱いやすくしたラッパーで、`(name, url, children)` が位置引数、`styles?` / `state?` / `trigger?` が既定値付きの名前付き引数です。

### HTML 出力

```html
<wc-counter
  luna:wc-url="/static/wc-counter.js"
  luna:wc-state="0"
  luna:wc-trigger="load"
>
  <template shadowrootmode="open">
    <style>:host { display: block; }</style>
    <button>Count: 0</button>
  </template>
</wc-counter>
```

## スロット

`slot` 用のヘルパーはありません。タグ名・属性タプル列・子要素を取る `@luna.h` で組み立てます:

```moonbit
@server_dom.wc_island(
  "wc-card",
  "/static/wc-card.js",
  [
    @luna.h("slot", [], []),                                  // 既定スロット
    @luna.h("slot", [("name", @server_dom.attr("header"))], []),
    @luna.h("slot", [("name", @server_dom.attr("footer"))], []),
  ],
)
```

### HTML 出力

```html
<slot></slot>
<slot name="header"></slot>
<slot name="footer"></slot>
```

## 状態のシリアライズ

```moonbit
pub(all) struct CounterProps {
  initial : Int
  max : Int
} derive(ToJson, FromJson)

// ComponentRef ベース(推奨)— シリアライズは自動
@sol.island(
  @types.counter({ initial: 0, max: 100 }),
  [@element.div([@element.text("Loading...")])],
)

// 文字列ベース(低レベル)— 手動シリアライズ
let state : CounterProps = { initial: 0, max: 100 }
@sol.island_raw(
  "wc-counter",
  "/static/counter.js",
  state.to_json().stringify(),
  [@element.div([@element.text("Loading...")])],
)
```

## クライアント側のハイドレーション

Sol と Astra は wc-loader(`@luna_ui/luna-loader`)を描画後の HTML に自動で注入します。手動でブートストラップする必要はありません。

### ハイドレーションの流れ

1. ローダーが `[luna:wc-url]` を持つ要素を走査する
2. `luna:wc-trigger` に応じて:
   - `load`: 即座にモジュールを import
   - `idle`: `requestIdleCallback` を使う
   - `visible`: `IntersectionObserver` を使う
   - `media:(query)`: `matchMedia` を使う
   - `none`: 手動の `window.__LUNA_WC_HYDRATE__(el)` を待つ
3. モジュールの `export default`(または名前付きの `hydrate`)が `(element, state, name)` で呼ばれる

### Island モジュールの構造

```typescript
// /components/counter.js
import { createSignal, render } from '@luna_ui/luna';

export default function hydrate(element: Element, state: { initial?: number }) {
  // state は luna:wc-state からパースされる
  const [count, setCount] = createSignal(state.initial ?? 0);

  render(element, () => (
    <button onClick={() => setCount(c => c + 1)}>
      Count: {count()}
    </button>
  ));
}
```

## API まとめ

| 関数 | 説明 |
|------|------|
| `@sol.island(cref, children)` | ComponentRef から Island を作成(推奨) |
| `@sol.island_with(cref, render)` | 描画関数から Island を作成 |
| `@sol.island_raw(name, url, state, children, trigger?)` | 文字列から Island を作成(低レベル) |
| `@server_dom.client(cref, children, styles?)` | `@sol.island` と同等 |
| `@luna.wc_island(...)` | Web Component Island を作成(低レベル) |
| `@sol.wc_island_raw(...)` | WC Island の sol 側ラッパー(低レベル) |
| `@luna.h("slot", attrs, [])` | スロット要素(専用ヘルパーなし) |
| `render_with_preloads(node)` | 描画して preload URL を収集 |

| Trigger | タイミング |
|---------|-----------|
| `@luna.Trigger::Load` | ページ読み込み時(既定) |
| `@luna.Trigger::Idle` | ブラウザのアイドル時 |
| `@luna.Trigger::Visible` | ビューポート内に入ったとき |
| `@luna.Trigger::Media(query)` | メディアクエリ一致時 |
| `@luna.Trigger::None` | 手動 |
