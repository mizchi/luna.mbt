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

### サーバーレンダリングされた HTML

サーバーが Web Component 属性を持つ Island をレンダリング：

> MoonBit でのサーバーサイドレンダリングについては、[MoonBit チュートリアル](/ja/luna/tutorial-moonbit/)を参照してください。

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
// wc-counter.ts
import { createSignal, hydrateWC } from '@luna_ui/luna';

interface CounterProps {
  initial: number;
}

function Counter(props: CounterProps) {
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

// Web Component として登録
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

## スタイルのカプセル化

Shadow DOM 内のスタイルはスコープ付き：

```css
/* これらはコンポーネントにのみ影響 */
:host {
  display: block;
  border: 1px solid #ccc;
}

button {
  /* 外側のボタンには影響しない */
  background: blue;
}
```

## WC vs 通常の Islands

| 観点 | 通常の Island | WC Island |
|------|-------------|-----------|
| スタイル | グローバル CSS | スコープ付き（Shadow DOM） |
| 要素 | `<div>` | カスタム要素 |
| SSR | `innerHTML` | Declarative Shadow DOM |
| スロット | サポートなし | サポート |
| 外部スタイリング | 簡単 | CSS parts が必要 |

### Web Components を使うタイミング

**WC Islands を使用：**
- スタイル分離が必要なコンポーネント
- 異なるプロジェクトで再利用可能
- スロットを持つコンポーネント
- デザインシステムコンポーネント

**通常の Islands を使用：**
- シンプルなインタラクティブウィジェット
- グローバルスタイルが必要なコンポーネント
- 素早いプロトタイピング

## CSS Parts

外部からのカスタマイズ用にスタイルフックを公開：

```typescript
// コンポーネント内
<button part="button">クリック</button>
```

```css
/* 外部から */
wc-counter::part(button) {
  background: red;  /* 内部スタイルを上書き */
}
```

## まとめ

Luna チュートリアルを完了しました！以下を学びました：

- **Signals** - リアクティブな状態
- **Effects** - 副作用
- **Memos** - 計算値
- **制御フロー** - 条件/リストレンダリング
- **ライフサイクル** - マウント/クリーンアップ
- **Islands** - 部分的ハイドレーション
- **Web Components** - カプセル化

## 次のステップ

- [JavaScript API リファレンス](/ja/luna/api-js/)を読む
- [MoonBit チュートリアル](/ja/luna/tutorial-moonbit/)でサーバーサイドレンダリングを学ぶ
