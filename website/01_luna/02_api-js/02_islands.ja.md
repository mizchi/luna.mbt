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

## hydrateWC 関数

```typescript
import { createSignal, hydrateWC } from '@luna_ui/luna';

function Counter(props: { count: number }) {
  const [count, setCount] = createSignal(props.count);

  return (
    <>
      <style>{`:host { display: block; }`}</style>
      <button onClick={() => setCount(c => c + 1)}>
        Count: {count()}
      </button>
    </>
  );
}

hydrateWC('wc-counter', Counter);
```
