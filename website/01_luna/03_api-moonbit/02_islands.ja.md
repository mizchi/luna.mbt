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

文字列パラメータで Island を作成します。型安全性のためには `island()` + `ComponentRef` を使用してください。

```moonbit
@sol.island_raw(
  "counter",
  "/static/counter.js",
  initial.to_string(),
  [button([text("Count: 0")])],
  trigger=@luna.Load,
)
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

## Web Components Island

```moonbit
@luna.wc_island(
  name="my-counter",
  url="/static/counter.js",
  trigger=@luna.Load,
  styles=":host { display: block; }",
  children=[
    // SSR コンテンツ
  ],
)
```
