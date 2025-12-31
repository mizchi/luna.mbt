# @luna_ui/luna-loader/hydration

Framework-agnostic SSR + Hydration utilities.

## Overview

このライブラリは SSR（サーバーサイドレンダリング）された HTML を採用（adopt）し、
インタラクティブ性を追加するためのユーティリティを提供します。

**特徴:**
- フレームワーク非依存: Luna (MoonBit), React, Preact, 素の HTML どれでも動作
- DOM-first: 既存の HTML を操作するだけで、再レンダリングしない
- 規約ベース: `data-*` 属性で状態を管理
- 軽量: 依存なし、tree-shakeable

## Installation

```ts
import {
  createHydrator,
  readOpenStates,
  enableTransitions,
  delegate,
} from '@luna_ui/luna-loader/hydration';
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

## Hydration Script

どの SSR フレームワークを使っても、hydration スクリプトは共通:

```ts
// switch-hydrate.js
export function hydrate(element, state, name) {
  if (element.dataset.hydrated) return;

  element.querySelectorAll('[data-switch-toggle]').forEach(btn => {
    btn.onclick = () => {
      const checked = btn.getAttribute('aria-checked') !== 'true';
      btn.setAttribute('aria-checked', checked);
      btn.style.background = checked ? 'var(--primary-color)' : '#4b5563';
      const thumb = btn.querySelector('[data-switch-thumb]');
      if (thumb) thumb.style.left = checked ? '22px' : '2px';
    };
  });

  element.dataset.hydrated = 'true';
}
```

## Core API

### createHydrator

Hydration 関数を作成。二重 hydration を自動防止。

```ts
export const hydrate = createHydrator((element, state, name) => {
  // セットアップ処理
  element.querySelector('button').onclick = () => { /* ... */ };

  // オプション: クリーンアップ関数を返す
  return () => { /* cleanup */ };
});
```

### State Reading

```ts
// 開閉状態を読み取り
const openItems = readOpenStates(element, 'data-accordion-item');
// Set { 'item-1' }

// チェック状態を読み取り
const checked = readCheckedStates(element, 'data-switch');
// Map { 'notifications' => true }

// 数値を読み取り
const value = readNumericValue(element, 'data-value', 0);
```

### Transitions

```ts
// 単一のトランジション
enableTransitions(element, '[data-content]', 'max-height', '0.3s');

// 複数のトランジション
enableMultipleTransitions(element, [
  { selector: '[data-content]', property: 'max-height' },
  { selector: '[data-chevron]', property: 'transform', duration: '0.2s' },
]);
```

### Event Handling

```ts
// イベント委譲
const cleanup = delegate(element, 'click', '[data-trigger]', (e, target) => {
  console.log('Clicked:', target.dataset.action);
});

// 直接ハンドラ
attachTriggers(element, '[data-button]', (trigger, data) => {
  console.log('Button:', data.action);
});
```

### State Updates

```ts
// 開閉状態
updateOpenState(item, isOpen, {
  contentSelector: '[data-content]',
  chevronSelector: '[data-chevron]',
});

// チェック状態
updateCheckedState(button, checked, {
  thumbSelector: '[data-thumb]',
});

// スライダー
updateSliderValue(slider, value, {
  min: 0,
  max: 100,
  rangeSelector: '[data-range]',
  thumbSelector: '[data-thumb]',
});
```

### Dialog Helpers

```ts
openDialog(dialog, overlay, content);
closeDialog(dialog, overlay, content);

const cleanup = setupEscapeHandler(dialog, () => closeDialog(dialog));
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

## HTML 要素の Web Component 化

```html
<!-- wc-loader で hydration -->
<switch-demo
  luna:trigger="visible"
  luna:wc-url="/components/switch-demo.js"
>
  <button data-switch-toggle aria-checked="true">
    <span data-switch-thumb></span>
  </button>
</switch-demo>
```

`luna:trigger` オプション:
- `load` - ページ読み込み時
- `visible` - ビューポートに入った時
- `idle` - ブラウザがアイドル時
- `media:query` - メディアクエリにマッチした時

## Best Practices

1. **SSR HTML は完全に機能する状態で出力**
   - JavaScript なしでも表示は正しく見える
   - Hydration は interactivity を追加するだけ

2. **状態は data-* 属性に埋め込む**
   - SSR 時に状態をシリアライズ
   - Hydration 時に読み取り

3. **二重 hydration を防止**
   - `data-hydrated` をチェック
   - `createHydrator` で自動化

4. **トランジションは hydration 後に有効化**
   - 初期表示のアニメーションフラッシュを防止
   - `requestAnimationFrame` で遅延

5. **イベント委譲を活用**
   - 動的に追加される要素にも対応
   - ハンドラ数を削減
