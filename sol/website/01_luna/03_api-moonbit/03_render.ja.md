---
title: Render
---

# Render

VNode から HTML 文字列へのレンダリング。

## render_to_string

VNode を HTML 文字列に変換します。

```moonbit
let node = div(class="container", [
  h1([text("Hello, World!")]),
  p([text("Welcome to Luna.")])
])

let html = @render.render_to_string(node)
// <div class="container"><h1>Hello, World!</h1><p>Welcome to Luna.</p></div>
```

## VNode 型

```moonbit
pub enum Node[E] {
  Element(VElement[E])      // HTML 要素
  Text(String)              // 静的テキスト
  DynamicText(() -> String) // 動的テキスト
  Fragment(Array[Node[E]])  // フラグメント
  Show(...)                 // 条件付きレンダリング
  For(...)                  // リストレンダリング
  Island(VIsland[E])        // Hydration 境界
  WcIsland(VWcIsland[E])    // Web Components Island
  Async(VAsync[E])          // 非同期ノード
}
```

## Attr 型

```moonbit
pub enum Attr[E] {
  VStatic(String)           // 静的値
  VDynamic(() -> String)    // Signal 連動
  VHandler(EventHandler[E]) // イベントハンドラ
  VAction(String)           // 宣言的アクション
}
```

## ヘルパー関数

```moonbit
// 要素作成
div(class="foo", [text("Hello")])
span(id="bar", [])
button(onclick=handler, [text("Click")])

// 属性
attr_static("value")
attr_dynamic(fn() { signal.get() })

// テキスト
text("Static text")
text_dyn(fn() { signal.get().to_string() })
```
