# @luna_ui/luna-loader/hydration

Framework-agnostic SSR + Hydration utilities.

## Overview

このライブラリは SSR（サーバーサイドレンダリング）された HTML を採用（adopt）し、
インタラクティブ性を追加するためのユーティリティを提供します。

**設計原則:**

1. **DOM-first**: 既存の HTML を操作するだけで、再レンダリングしない
2. **Attribute-only**: `data-*` と `aria-*` 属性のみ更新（インラインスタイルなし）
3. **CSS in SSR**: すべてのスタイリングは属性に対する CSS セレクタで行う
4. **Cleanup always**: すべての setup 関数は cleanup 関数を返す
5. **Framework-agnostic**: Luna (MoonBit), React, Preact, 素の HTML どれでも動作

## Installation

```ts
import {
  createHydrator,
  toggle,
  toggleChecked,
  setState,
  getState,
  onClick,
  on,
  onKey,
  onDrag,
  combine,
} from '@luna_ui/luna-loader/hydration';
```

## CSS Convention

Hydration スクリプトは属性を更新し、CSS がビジュアルを担当:

```css
/* Toggle states */
[data-state="open"] [data-content] { max-height: 200px; }
[data-state="closed"] [data-content] { max-height: 0; }

/* Checked states */
[aria-checked="true"] { background: var(--primary); }
[aria-checked="false"] { background: var(--muted); }

/* Transitions (CSS handles animation) */
[data-content] { transition: max-height 0.3s ease; }
```

## Core API

### createHydrator

Hydration 関数を作成。二重 hydration を自動防止。

```ts
import { createHydrator, onClick, toggle, combine } from '@luna_ui/luna-loader/hydration';

export const hydrate = createHydrator((element, state, name) => {
  // onClick returns cleanup function
  const cleanup = onClick(element, '[data-trigger]', (e, target) => {
    const item = target.closest('[data-item]');
    if (item) toggle(item, 'data-state', ['open', 'closed']);
  });

  return cleanup; // Always return cleanup
});
```

### Attribute Operations

```ts
// Toggle between two values
toggle(element, 'data-state', ['open', 'closed']);
// Returns: new value ('open' or 'closed')

// Toggle aria-checked
toggleChecked(button);
// Returns: new checked state (boolean)

// Set/get data-state
setState(element, 'open');
getState(element); // 'open' | undefined

// Set/get aria-checked
setChecked(element, true);
getChecked(element); // boolean

// Set/get numeric value (aria-valuenow + data-value)
setValue(element, 50);
getValue(element, 0); // number
```

### State Reading

SSR HTML から初期状態を読み取る:

```ts
// Read data-state from items
const states = readStates(element, 'data-accordion-item');
// Map { 'item-1' => 'open', 'item-2' => 'closed' }

// Read aria-checked from items
const checked = readChecked(element, 'data-switch');
// Map { 'switch-1' => true, 'switch-2' => false }

// Read numeric range
const { min, max, value } = readRange(slider);
// { min: 0, max: 100, value: 50 }
```

### Event Handling

すべてのイベントハンドラは cleanup 関数を返す:

```ts
// Click with delegation
const cleanup1 = onClick(element, '[data-trigger]', (event, target) => {
  // target is the matched element
});

// Any event with delegation
const cleanup2 = on(element, 'change', 'input', (event, target) => {
  // ...
});

// Keyboard
const cleanup3 = onKey(document, 'Escape', (event) => {
  // ...
}, { condition: () => isOpen });

// Drag (mouse + touch)
const cleanup4 = onDrag(thumb, {
  onStart: (x, y) => { /* optional */ },
  onMove: (x, y) => { /* required */ },
  onEnd: () => { /* optional */ },
});

// Combine cleanups
const cleanup = combine(cleanup1, cleanup2, cleanup3, cleanup4);
```

### Utilities

```ts
// Query helpers
$(element, '[data-trigger]');     // querySelector
$$(element, '[data-item]');       // querySelectorAll as array
closest(element, '[data-root]');  // closest ancestor
data(element, 'itemId');          // dataset value

// Combine cleanups
const cleanup = combine(cleanup1, cleanup2, cleanup3);
```

## SSR Framework Examples

### Luna (MoonBit)

```moonbit
fn render_switch(checked : Bool) -> @luna.Node[Unit] {
  @luna.h("button", [
    ("data-switch-toggle", @luna.attr_static("")),
    ("aria-checked", @luna.attr_static(checked.to_string())),
  ], [
    @luna.h("span", [("data-switch-thumb", @luna.attr_static(""))], []),
  ])
}
```

### React / Preact

```tsx
function Switch({ checked }: { checked: boolean }) {
  return (
    <button data-switch-toggle aria-checked={checked}>
      <span data-switch-thumb />
    </button>
  );
}
```

### Plain HTML

```html
<button data-switch-toggle aria-checked="true">
  <span data-switch-thumb></span>
</button>
```

## Complete Example: Switch

### SSR HTML

```html
<switch-demo luna:trigger="visible">
  <button data-switch-toggle aria-checked="true">
    <span data-switch-thumb></span>
  </button>
</switch-demo>
```

### CSS (SSR side)

```css
[data-switch-toggle] {
  position: relative;
  width: 44px;
  height: 24px;
  border-radius: 12px;
  transition: background 0.2s ease;
}

[data-switch-toggle][aria-checked="true"] {
  background: var(--primary-color);
}

[data-switch-toggle][aria-checked="false"] {
  background: var(--muted-color);
}

[data-switch-thumb] {
  position: absolute;
  width: 20px;
  height: 20px;
  border-radius: 50%;
  background: white;
  transition: transform 0.2s ease;
}

[aria-checked="true"] [data-switch-thumb] {
  transform: translateX(20px);
}

[aria-checked="false"] [data-switch-thumb] {
  transform: translateX(0);
}
```

### Hydration Script

```ts
// switch-hydrate.js
export function hydrate(element, state, name) {
  if (element.dataset.hydrated) return;

  element.querySelectorAll('[data-switch-toggle]').forEach(btn => {
    btn.onclick = () => {
      const checked = btn.getAttribute('aria-checked') !== 'true';
      btn.setAttribute('aria-checked', String(checked));
    };
  });

  element.dataset.hydrated = 'true';
}
```

## Numeric Values with CSS Custom Properties

動的な数値（スライダー、プログレスバーなど）には CSS カスタムプロパティを使用:

```ts
// Update CSS variable for dynamic positioning
slider.style.setProperty('--slider-percent', String(pct));
```

```css
[data-slider-range] {
  width: calc(var(--slider-percent, 50) * 1%);
}

[data-slider-thumb] {
  left: calc(var(--slider-percent, 50) * 1%);
}
```

## data-* Attribute Conventions

| 属性 | 用途 | 例 |
|-----|------|-----|
| `data-state` | 開閉状態 | `open`, `closed` |
| `data-{component}` | アイテム識別 | `data-accordion-item="id"` |
| `data-{component}-trigger` | トリガー要素 | `data-accordion-trigger` |
| `data-{component}-content` | コンテンツ | `data-accordion-content` |
| `data-hydrated` | Hydration済み | `true` |
| `data-value` | 数値状態 | `50` |
| `data-min`, `data-max` | 範囲 | `0`, `100` |

## aria-* Attributes

| 属性 | 用途 |
|-----|------|
| `aria-checked` | チェック状態 (`true`, `false`, `mixed`) |
| `aria-expanded` | 展開状態 |
| `aria-valuenow` | 現在値 |
| `aria-valuemin`, `aria-valuemax` | 値の範囲 |
| `aria-modal` | モーダル表示 |

## Best Practices

1. **Hydration は属性のみ更新**
   - `data-*` と `aria-*` 属性だけを操作
   - インラインスタイルは使わない（CSS カスタムプロパティは例外）

2. **CSS がビジュアルを担当**
   - 属性セレクタでスタイルを定義
   - トランジションも CSS で定義

3. **常に cleanup を返す**
   - イベントリスナーの登録解除
   - SPA ナビゲーション対応

4. **二重 hydration を防止**
   - `data-hydrated` をチェック
   - `createHydrator` で自動化

5. **イベント委譲を活用**
   - 動的に追加される要素にも対応
   - ハンドラ数を削減
