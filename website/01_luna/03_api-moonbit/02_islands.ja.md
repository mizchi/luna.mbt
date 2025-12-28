---
title: Islands
---

# Islands

Island Architecture による部分的ハイドレーション。

## VIsland

```moonbit
pub fn island(
  id : String,
  url : String,
  trigger : TriggerType,
  state : @js.Any,
  children : Array[Node[E]],
) -> Node[E]
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

## 使用例

```moonbit
let counter_state = { count: 0 }

@luna.island(
  id="counter",
  url="/static/counter.js",
  trigger=TriggerType::Visible,
  state=@json.stringify(counter_state),
  [
    button([text("Count: 0")])
  ]
)
```

## Web Components Island

```moonbit
@luna.wc_island(
  tag="my-counter",
  url="/static/counter.js",
  trigger=TriggerType::Load,
  attrs=[("initial", "0")],
  [
    // SSR コンテンツ
  ]
)
```
