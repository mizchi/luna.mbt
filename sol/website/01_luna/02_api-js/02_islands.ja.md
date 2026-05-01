---
title: Islands
---

# Islands

Island Architecture による部分的ハイドレーション。

## 基本的な使い方

```html
<div luna:id="counter"
     luna:url="/static/counter.js"
     luna:state='{"count":0}'
     luna:client-trigger="visible">
  <button>Count: 0</button>
</div>
```

## 属性

| 属性 | 説明 |
|------|------|
| `luna:id` | コンポーネント識別子 |
| `luna:url` | JavaScript モジュール URL |
| `luna:state` | シリアライズされた初期状態 |
| `luna:client-trigger` | ハイドレーション戦略 |

## トリガー

| トリガー | タイミング |
|---------|-----------|
| `load` | ページロード時に即座 |
| `idle` | requestIdleCallback 時 |
| `visible` | IntersectionObserver 検知時 |
| `media` | メディアクエリマッチ時 |
| `none` | 手動トリガー |

## hydrate 関数

```typescript
import { hydrate } from '@luna_ui/luna';

hydrate('counter', (element, props) => {
  const [count, setCount] = createSignal(props.count);

  element.querySelector('button').onclick = () => {
    setCount(c => c + 1);
  };

  createEffect(() => {
    element.querySelector('button').textContent = `Count: ${count()}`;
  });
});
```

## Web Components

```typescript
import { hydrateWC } from '@luna_ui/luna';

hydrateWC('my-counter', (shadowRoot, props) => {
  // Shadow DOM 内での操作
});
```
