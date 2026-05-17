---
title: Islands
---

# Islands

Web Components による部分的ハイドレーション。

## 基本的な使い方

```html
<wc-counter
  luna:wc-url="/static/wc-counter.js"
  luna:wc-state='{"count":0}'
  luna:wc-trigger="visible">
  <template shadowrootmode="open">
    <button>Count: 0</button>
  </template>
</wc-counter>
```

Custom Element として `customElements.define()` を呼ぶ必要は **無い**。 loader は `[luna:wc-url]` 属性を持つ要素を直接スキャンする。 Declarative Shadow DOM (`<template shadowrootmode="open">`) はオプション。

## 属性

| 属性 | 説明 |
|------|------|
| `luna:wc-url` | JavaScript モジュール URL |
| `luna:wc-state` | シリアライズされた初期状態 (JSON) |
| `luna:wc-trigger` | ハイドレーション戦略 |

## トリガー

| トリガー | タイミング |
|---------|-----------|
| `load` | ページロード時に即座 |
| `idle` | requestIdleCallback 時 |
| `visible` | IntersectionObserver 検知時 |
| `media` | メディアクエリマッチ時 |
| `none` | 手動トリガー |

## Island モジュール契約

`luna:wc-url` が指す JavaScript モジュールは `hydrate` 関数 (名前付き or default export) を公開する。 wc-loader が動的 import し、 以下のシグネチャで呼ぶ:

```typescript
hydrate(element: Element, state: unknown, name: string): void | (() => void)
```

- `element` — Custom Element の実体 (例: `<wc-counter>`)
- `state` — `luna:wc-state` (JSON) のパース結果。 属性が無ければ `{}`
- `name` — 要素のタグ名 (例: `"wc-counter"`)
- 戻り値に cleanup function を返すと HMR / 切り離し時に呼ばれる

```typescript
import { createSignal, render } from '@luna_ui/luna';

interface CounterProps {
  count: number;
}

export default function hydrate(element: Element, state: CounterProps) {
  const [count, setCount] = createSignal(state.count);

  render(element, () => (
    <>
      <style>{`:host { display: block; }`}</style>
      <button onClick={() => setCount(c => c + 1)}>
        Count: {count()}
      </button>
    </>
  ));
}
```
