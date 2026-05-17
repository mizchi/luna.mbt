---
title: Islands
---

# Islands

Island Architecture による部分的ハイドレーション。

## island（ComponentRef ベース、推奨）

型安全な `ComponentRef` を使用して Island を作成します。ファクトリ関数は `sol generate` がクライアントの Props 型から自動生成します。

```moonbit
// 自動生成: app/__gen__/types/types.mbt
pub struct CounterProps { initial_count : Int } derive(ToJson, FromJson)
pub fn counter(props : CounterProps, trigger~ : @luna.Trigger) -> @luna.ComponentRef[CounterProps]
```

```moonbit
// サーバーサイドでの使用
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

## island_raw（文字列ベース、低レベル）

Web Components Island を文字列パラメータで作成します。 内部で `@luna.wc_island` に委譲し、 `island()` と同じ `<wc-*>` マークアップを出力します。 型安全性のためには `island()` + `ComponentRef` を推奨。

```moonbit
@sol.island_raw(
  "wc-counter",          // Custom element タグ名
  "/static/counter.js",
  initial.to_string(),
  [button([text("Count: 0")])],
  trigger=@luna.Load,
)
```

### HTML 出力

```html
<wc-counter
  luna:wc-url="/static/counter.js"
  luna:wc-state="0"
  luna:wc-trigger="load"
>
  <button>Count: 0</button>
</wc-counter>
```

## TriggerType

```moonbit
pub enum TriggerType {
  Load      // ページロード時
  Idle      // requestIdleCallback 時
  Visible   // IntersectionObserver 検知時
  Media(String)  // メディアクエリマッチ時
  None      // 手動トリガー
}
```

## Web Components Island (低レベル)

`@sol.island()` は既に Web Component マークアップを出力します。 以下は同じ machinery への直接エントリポイントで、 タグ名・scoped style・ComponentRef を介さない構築が必要な場合に使用します。

### wc_island_raw / @luna.wc_island

```moonbit
@luna.wc_island(
  name="wc-counter",
  url="/static/counter.js",
  trigger=@luna.Load,
  styles=":host { display: block; }",
  children=[
    // SSR コンテンツ
  ],
)
```

### クライアント側 hydrate モジュール

`luna:wc-url` が指すモジュールは `hydrate` (named export か default export) を公開する。 wc-loader が動的 import し、 `(element, state, name)` で呼ぶ。

```typescript
// /static/counter.js
import { createSignal, render } from '@luna_ui/luna';

export default function hydrate(element: Element, state: { initial?: number }) {
  const [count, setCount] = createSignal(state.initial ?? 0);

  render(element, () => (
    <button onClick={() => setCount(c => c + 1)}>
      Count: {count()}
    </button>
  ));
}
```
