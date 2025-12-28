---
title: "Islands: 基本"
---

# Islands の基本

部分的なハイドレーションのためのサーバーサイド Island レンダリング。

## Island とは？

Island は以下を行うコンポーネントです：
- サーバーで HTML をレンダリング（MoonBit）
- クライアントでインタラクティブになる（TypeScript）
- その特定のコンポーネントのみに JavaScript をロード

```
┌─────────────────────────────────────┐
│  ヘッダー（静的）     ← JS なし     │
├─────────────────────────────────────┤
│  記事（静的）         ← JS なし     │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ コメント Island    ← JS     │    │
│  └─────────────────────────────┘    │
│                                     │
│  フッター（静的）     ← JS なし     │
└─────────────────────────────────────┘
```

## Island の作成

### サーバーサイド（MoonBit）

```moonbit
using @server_dom { island, div, button, text }
using @luna { Load }

fn counter_island(initial : Int) -> @luna.Node {
  island(
    id="counter",
    url="/static/counter.js",
    state=initial.to_string(),
    trigger=Load,
    children=[
      div([
        button([text("Count: " + initial.to_string())])
      ])
    ],
  )
}
```

### HTML 出力

```html
<div
  luna:id="counter"
  luna:url="/static/counter.js"
  luna:state="0"
  luna:client-trigger="load"
>
  <div>
    <button>Count: 0</button>
  </div>
</div>
```

### クライアントサイド（TypeScript）

クライアントサイドコードが Island をハイドレート：

```typescript
// counter.ts
import { createSignal, hydrate } from '@luna_ui/luna';

function Counter(props) {
  const [count, setCount] = createSignal(props.initial);

  return (
    <button onClick={() => setCount(c => c + 1)}>
      Count: {count()}
    </button>
  );
}

hydrate("counter", Counter);
```

## Island 属性

| 属性 | MoonBit パラメータ | 説明 |
|-----|-------------------|------|
| `luna:id` | `id` | コンポーネント識別子 |
| `luna:url` | `url` | JavaScript モジュール URL |
| `luna:state` | `state` | シリアライズされた props（JSON） |
| `luna:client-trigger` | `trigger` | いつハイドレートするか |

## 複数の Islands

各 Island は独立：

```moonbit
fn page() -> @luna.Node {
  div([
    header([text("マイページ")]),

    // 検索 Island - 即座にハイドレート
    search_island(),

    // 記事 - 純粋な HTML、JS なし
    article([text("静的コンテンツ...")]),

    // コメント Island - 表示時にハイドレート
    comments_island(post_id=123),

    footer([text("フッター")]),
  ])
}
```

## メリット

| メトリック | 従来の SPA | Islands |
|----------|-----------|---------|
| 初期 JS | 100KB+ | ~3KB ローダー |
| TTI | 遅い | 速い |
| LCP | JS でブロック | 即座 |

## 試してみよう

「いいね」ボタン用の Island を作成：
1. サーバーが初期いいね数でボタンをレンダリング
2. クライアントがハイドレートしてクリック可能に
3. クリックでカウントをインクリメント

## 次へ

[Islands State →](./islands_state) について学ぶ
