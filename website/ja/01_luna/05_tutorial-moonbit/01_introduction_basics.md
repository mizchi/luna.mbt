---
title: "導入: 基本"
---

# 最初の Luna コンポーネント

シンプルなカウンターを作成して Luna のコア概念を理解しましょう。

## クイックスタート

最も速い方法は CLI を使用することです：

```bash
npx @luna_ui/luna new myapp --mbt
cd myapp
moon update
npm install
npm run dev
```

これにより Vite と vite-plugin-moonbit が設定された新しい MoonBit プロジェクトが作成されます。

## MoonBit でのカウンター

```moonbit
using @server_dom { div, p, button, text }
using @luna { signal }

fn counter() -> @luna.Node {
  let count = signal(0)

  div([
    p([text("Count: " + count.get().to_string())]),
    button([text("Increment")]),
  ])
}
```

## 詳細な解説

### 1. インポート

```moonbit
using @server_dom { div, p, button, text }
using @luna { signal }
```

- `@server_dom` はサーバーサイドレンダリング用の HTML 要素ファクトリを提供
- `@luna` は `signal` などのリアクティブプリミティブを提供

### 2. リアクティブな状態を作成

```moonbit
let count = signal(0)
```

`signal(0)` は以下のリアクティブ値を作成：
- `0` から開始
- `.get()` で読み取り可能
- `.set()` または `.update()` で更新可能

### 3. DOM を構築

```moonbit
div([
  p([text("Count: " + count.get().to_string())]),
  button([text("Increment")]),
])
```

要素はファクトリ関数で作成：
- `div([...])` は子要素を持つ `<div>` を作成
- `text("...")` はテキストノードを作成

## HTML へのレンダリング

コンポーネントをレンダリング：

```moonbit
fn main {
  let node = counter()
  let html = @renderer.render_to_string(node)
  println(html)
}
```

出力：

```html
<div><p>Count: 0</p><button>Increment</button></div>
```

## サーバーサイド vs クライアントサイド

Luna の Islands アーキテクチャでは：

| 場所 | 内容 |
|-----|------|
| サーバー（MoonBit） | 初期 HTML をレンダリング |
| クライアント（TypeScript） | ハイドレーションでインタラクティビティを追加 |

## Island を使った完全な例

```moonbit
using @server_dom { island, div, p, button, text }
using @luna { signal, Load }

fn counter_island(initial : Int) -> @luna.Node {
  island(
    id="counter",
    url="/static/counter.js",
    state=initial.to_string(),
    trigger=Load,
    children=[
      div([
        p([text("Count: " + initial.to_string())]),
        button([text("Increment")]),
      ])
    ],
  )
}
```

## 試してみよう

1. "Hello, Luna!" を表示するコンポーネントを作成
2. 名前用の Signal を追加して "Hello, {name}!" を表示

## 次へ

[Signals →](./introduction_signals) について学ぶ
