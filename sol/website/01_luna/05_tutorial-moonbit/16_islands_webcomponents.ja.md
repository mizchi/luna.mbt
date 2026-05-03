---
title: "Islands: Web Components"
---

# Web Components Islands

Islands と Web Components を組み合わせてスタイルのカプセル化と相互運用性を実現します。

## なぜ Web Components か？

Web Components が提供するもの：

| 機能 | メリット |
|-----|---------|
| Shadow DOM | スタイルのカプセル化 |
| Custom Elements | 標準 API |
| Declarative Shadow DOM | SSR サポート |
| 相互運用性 | どこでも動作 |

## Web Component Island の作成

### サーバーサイド（MoonBit）

```moonbit
using @server_dom { wc_island, template, style, button, text }
using @luna { Load }

fn counter_wc(initial : Int) -> @luna.Node {
  wc_island(
    tag="wc-counter",
    url="/static/wc-counter.js",
    state=initial.to_string(),
    trigger=Load,
    children=[
      template(shadowrootmode="open", [
        style([text(":host { display: block; padding: 16px; } button { background: blue; color: white; }")]),
        button([text("Count: " + initial.to_string())]),
      ])
    ],
  )
}
```

### HTML 出力

```html
<wc-counter
  luna:wc-url="/static/wc-counter.js"
  luna:wc-state="0"
  luna:wc-trigger="load"
>
  <template shadowrootmode="open">
    <style>
      :host { display: block; padding: 16px; }
      button { background: blue; color: white; }
    </style>
    <button>Count: 0</button>
  </template>
</wc-counter>
```

### クライアントサイド（TypeScript）

```typescript
import { createSignal, hydrateWC } from '@luna_ui/luna';

function Counter(props) {
  const [count, setCount] = createSignal(props.initial);

  return (
    <>
      <style>
        {`:host { display: block; padding: 16px; }
          button { background: blue; color: white; }`}
      </style>
      <button onClick={() => setCount(c => c + 1)}>
        Count: {count()}
      </button>
    </>
  );
}

hydrateWC("wc-counter", Counter);
```

## Declarative Shadow DOM

Luna は SSR に Declarative Shadow DOM を使用：

```html
<my-component>
  <template shadowrootmode="open">
    <style>/* スコープ付きスタイル */</style>
    <!-- Shadow DOM コンテンツ -->
  </template>
</my-component>
```

**メリット：**
- スタイルが即座に適用（FOUC なし）
- 初期レンダリングに JavaScript 不要
- ハイドレーション前にコンテンツが表示

## WC vs 通常の Islands

| 観点 | 通常の Island | WC Island |
|------|-------------|-----------|
| スタイル | グローバル CSS | スコープ付き |
| 要素 | `<div>` | カスタム要素 |
| SSR | `innerHTML` | Declarative Shadow DOM |

## まとめ

Luna MoonBit チュートリアルを完了しました！以下を学びました：

- **Signals** - リアクティブな状態
- **Effects** - 副作用
- **Memos** - 計算値
- **制御フロー** - 条件/リストレンダリング
- **ライフサイクル** - マウント/クリーンアップ
- **Islands** - サーバーサイドレンダリングと部分的ハイドレーション
- **Web Components** - スタイルカプセル化

## 次のステップ

- [MoonBit API リファレンス](/ja/luna/api-moonbit/)を読む
- [JavaScript チュートリアル](/ja/luna/tutorial-js/)でクライアントサイドハイドレーションを学ぶ
