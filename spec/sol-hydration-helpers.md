# Sol Hydration Helpers 設計仕様

## 現状の問題

`website/components/*-demo.js` に共通パターンが散在：

```javascript
// 全ファイルに重複
export function hydrate(element, state, name) {
  if (element.dataset.hydrated) return;
  // ... 処理 ...
  element.dataset.hydrated = 'true';
}
```

## 目標

1. **共通パターンをヘルパーとして提供**
2. **型安全性**: TypeScript で書いて `.d.ts` 提供
3. **軽量**: tree-shakable、必要な機能のみバンドル
4. **CSS-first**: JS は最小限、CSS セレクタで視覚変更

## API 設計

### 1. createHydrator - 基本ラッパー

```typescript
import { createHydrator } from '@luna/hydration';

export const hydrate = createHydrator((el, state) => {
  // 自動的に hydrated チェック済み
  // el.dataset.hydrated は自動設定
});
```

### 2. toggle - 二値状態トグル

```typescript
import { toggle } from '@luna/hydration';

// data-state="open|closed" をトグル
toggle(element, '[data-accordion-trigger]', {
  target: '[data-accordion-item]',
  states: ['open', 'closed'],
  attribute: 'data-state'  // default
});

// aria-checked="true|false" をトグル
toggle(element, '[data-switch-toggle]', {
  attribute: 'aria-checked',
  states: ['true', 'false']
});
```

### 3. onDelegate - イベント委譲

```typescript
import { onDelegate } from '@luna/hydration';

onDelegate(element, 'click', '[data-dialog-trigger]', () => {
  dialog.dataset.state = 'open';
});
```

### 4. keyboard - キーボードハンドリング

```typescript
import { keyboard } from '@luna/hydration';

keyboard(element, {
  Escape: () => close(),
  ArrowUp: () => increment(),
  ArrowDown: () => decrement()
});
```

### 5. drag - ドラッグ操作

```typescript
import { drag } from '@luna/hydration';

drag(element, '[data-slider-track]', {
  onMove: (percent) => {
    slider.style.setProperty('--slider-percent', String(percent * 100));
  }
});
```

## ファイル構成

```
js/luna/src/hydration/
├── index.ts           # 公開API
├── createHydrator.ts  # 基本ラッパー
├── toggle.ts          # トグルヘルパー
├── delegate.ts        # イベント委譲
├── keyboard.ts        # キーボード
└── drag.ts            # ドラッグ操作
```

## 使用例: switch-demo.js リファクタ

**Before:**
```javascript
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

**After:**
```javascript
import { createHydrator, toggle } from '@luna/hydration';

export const hydrate = createHydrator((el) => {
  toggle(el, '[data-switch-toggle]', {
    attribute: 'aria-checked',
    states: ['true', 'false']
  });
});
```

## 使用例: accordion-demo.js リファクタ

**Before:**
```javascript
export function hydrate(element, state, name) {
  if (element.dataset.hydrated) return;
  element.querySelectorAll('[data-accordion-trigger]').forEach(trigger => {
    const item = trigger.closest('[data-accordion-item]');
    if (item) {
      trigger.onclick = () => {
        item.dataset.state = item.dataset.state === 'open' ? 'closed' : 'open';
      };
    }
  });
  element.dataset.hydrated = 'true';
}
```

**After:**
```javascript
import { createHydrator, toggle } from '@luna/hydration';

export const hydrate = createHydrator((el) => {
  toggle(el, '[data-accordion-trigger]', {
    target: '[data-accordion-item]',
    states: ['open', 'closed']
  });
});
```

## 使用例: slider-demo.js リファクタ

**After:**
```javascript
import { createHydrator, drag, keyboard } from '@luna/hydration';

export const hydrate = createHydrator((el) => {
  el.querySelectorAll('[data-slider]').forEach(slider => {
    const min = +slider.dataset.min || 0;
    const max = +slider.dataset.max || 100;

    const update = (percent) => {
      const value = Math.round(min + percent * (max - min));
      slider.dataset.value = String(value);
      slider.style.setProperty('--slider-percent', String(percent * 100));
    };

    drag(slider, '[data-slider-track], [data-slider-thumb]', { onMove: update });

    keyboard(slider.querySelector('[data-slider-thumb]'), {
      ArrowRight: () => update((+slider.dataset.value - min) / (max - min) + 0.01),
      ArrowLeft: () => update((+slider.dataset.value - min) / (max - min) - 0.01)
    });
  });
});
```

## 段階的導入

1. **Phase 1**: `createHydrator` + `toggle` を実装、switch/checkbox/accordion に適用
2. **Phase 2**: `onDelegate` + `keyboard` を追加、dialog に適用
3. **Phase 3**: `drag` を追加、slider に適用

## 検討事項

- [ ] SSR側での状態埋め込み規約との統合
- [ ] cleanup 関数のサポート（コンポーネント削除時のリソース解放）
- [ ] 型定義の自動生成（experimental_ir との連携）
