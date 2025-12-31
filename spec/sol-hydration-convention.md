# Sol SSR + Hydration Convention

Sol/Astra における SSR + Hydration パターンの規約。
Next.js + Astro のような開発体験を目指す。

## 概要

Sol は Island Architecture を採用し、以下の原則に基づく:

1. **SSR First**: すべてのコンポーネントはサーバーで HTML を生成
2. **Progressive Hydration**: JavaScript は必要な時に必要な分だけ読み込み
3. **Attribute-based State**: 状態は `data-*` / `aria-*` 属性で管理
4. **CSS-driven Styling**: ビジュアル変更は CSS セレクタで制御

## ディレクトリ構成

```
website/
├── components/           # Hydration スクリプト (.js)
│   ├── accordion-demo.js
│   ├── switch-demo.js
│   └── dialog-demo.js
├── styles/               # コンポーネント CSS (optional)
│   └── accordion.css
├── 01_section/           # コンテンツ
│   └── page.mdx
└── astra.json            # 設定
```

## コンポーネント定義

### 1. SSR テンプレート（MoonBit）

```moonbit
// src/components/switch.mbt
pub fn switch(checked : Bool) -> @luna.Node[Unit] {
  @luna.h("button", [
    ("data-switch-toggle", @luna.attr_static("")),
    ("aria-checked", @luna.attr_static(checked.to_string())),
    ("role", @luna.attr_static("switch")),
  ], [
    @luna.h("span", [("data-switch-thumb", @luna.attr_static(""))], []),
  ])
}
```

### 2. Hydration スクリプト

```javascript
// components/switch-demo.js

// SSR HTML Convention (コメントで明記)
//   <switch-demo luna:wc-url="/components/switch-demo.js" luna:wc-trigger="visible">
//     <button data-switch-toggle aria-checked="true|false">
//       <span data-switch-thumb></span>
//     </button>
//   </switch-demo>
//
// Required CSS:
//   [aria-checked="true"] { background: var(--primary); }
//   [aria-checked="false"] { background: var(--muted); }

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

export default hydrate;
```

### 3. CSS（SSR 側で完結）

```css
/* styles/switch.css */
[data-switch-toggle] {
  position: relative;
  width: 44px;
  height: 24px;
  border-radius: 12px;
  border: none;
  cursor: pointer;
  transition: background 0.2s ease;
}

[data-switch-toggle][aria-checked="true"] {
  background: var(--primary-color, #6366f1);
}

[data-switch-toggle][aria-checked="false"] {
  background: var(--muted-color, #4b5563);
}

[data-switch-thumb] {
  position: absolute;
  top: 2px;
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

## MDX での使用

```mdx
---
title: Switch Component
---

# Switch

<switch-demo
  luna:wc-url="/components/switch-demo.js"
  luna:wc-trigger="visible"
>
  <button data-switch-toggle aria-checked="true">
    <span data-switch-thumb></span>
  </button>
</switch-demo>
```

## Hydration トリガー

`luna:wc-trigger` で読み込みタイミングを制御:

| トリガー | 説明 | 使用場面 |
|---------|------|---------|
| `load` | ページ読み込み時 | 常に表示されるUI |
| `visible` | ビューポート進入時 | スクロールで見えるコンテンツ |
| `idle` | ブラウザアイドル時 | 優先度の低いUI |
| `media:(query)` | メディアクエリマッチ時 | レスポンシブUI |

```html
<!-- 画面内に入ったら読み込み（推奨） -->
<accordion-demo luna:wc-trigger="visible">...</accordion-demo>

<!-- 即座に読み込み -->
<header-nav luna:wc-trigger="load">...</header-nav>

<!-- アイドル時に読み込み -->
<footer-widget luna:wc-trigger="idle">...</footer-widget>

<!-- モバイルのみ -->
<mobile-menu luna:wc-trigger="media:(max-width: 768px)">...</mobile-menu>
```

## 属性規約

### 状態属性

| 属性 | 用途 | 値 |
|-----|------|-----|
| `data-state` | 開閉状態 | `open`, `closed` |
| `aria-checked` | チェック状態 | `true`, `false`, `mixed` |
| `aria-expanded` | 展開状態 | `true`, `false` |
| `aria-valuenow` | 現在値 | 数値 |
| `data-hydrated` | Hydration完了 | `true` |

### 構造属性

| パターン | 説明 |
|---------|------|
| `data-{component}` | コンポーネントルート |
| `data-{component}-trigger` | トリガー要素 |
| `data-{component}-content` | コンテンツ領域 |
| `data-{component}-item="id"` | 識別可能なアイテム |

```html
<div data-accordion>
  <div data-accordion-item="section-1" data-state="open">
    <button data-accordion-trigger>Title</button>
    <div data-accordion-content>Content</div>
  </div>
</div>
```

## Hydration スクリプト規約

### 必須エクスポート

```javascript
// 必須: hydrate 関数
export function hydrate(element, state, name) {
  // element: ルート要素
  // state: SSR から渡された状態（オプション）
  // name: コンポーネント名
}

// 推奨: default export
export default hydrate;
```

### 設計原則

1. **二重 hydration 防止**
   ```javascript
   if (element.dataset.hydrated) return;
   element.dataset.hydrated = 'true';
   ```

2. **属性のみ更新**（インラインスタイル禁止）
   ```javascript
   // Good
   btn.setAttribute('aria-checked', 'true');
   item.dataset.state = 'open';

   // Bad
   btn.style.background = 'blue';
   ```

3. **数値は CSS カスタムプロパティ**
   ```javascript
   // スライダーなど動的値が必要な場合のみ
   slider.style.setProperty('--slider-percent', String(pct));
   ```

4. **cleanup 対応**（SPA 用）
   ```javascript
   export function hydrate(element, state, name) {
     const handler = () => { /* ... */ };
     document.addEventListener('keydown', handler);

     // オプション: cleanup を返す
     return () => document.removeEventListener('keydown', handler);
   }
   ```

## ビルド出力

```
dist/
├── components/           # ページ固有チャンク（バンドルなし）
│   ├── accordion-demo.js
│   └── switch-demo.js
├── assets/
│   ├── loader.js         # 共通ローダー（~2KB）
│   └── style.css         # 共通スタイル
└── luna/
    └── radix-components/
        └── accordion/
            └── index.html
```

- 各コンポーネントは個別ファイル（共通チャンクなし）
- `luna:wc-trigger` による遅延読み込み
- loader.js が MutationObserver で動的追加を監視

## 型安全性（TypeScript）

```typescript
// hydration.d.ts
export interface HydrateFunction {
  (element: Element, state: unknown, name: string): void | (() => void);
}

export interface HydrationModule {
  hydrate: HydrateFunction;
  default?: HydrateFunction;
}
```

## チェックリスト

新しいコンポーネントを追加する際の確認事項:

- [ ] SSR テンプレートが JavaScript なしで正しく表示される
- [ ] `data-*` / `aria-*` 属性で状態が表現されている
- [ ] CSS が属性セレクタでスタイルを定義している
- [ ] Hydration スクリプトがインラインスタイルを使っていない
- [ ] `data-hydrated` チェックで二重 hydration を防止している
- [ ] コメントで SSR HTML Convention と Required CSS を記載している
- [ ] 適切な `luna:wc-trigger` を選択している

## React/Preact 互換

同じ規約は React/Preact でも使用可能:

```tsx
// React SSR
function Switch({ checked }: { checked: boolean }) {
  return (
    <button
      data-switch-toggle
      aria-checked={checked}
      role="switch"
    >
      <span data-switch-thumb />
    </button>
  );
}
```

Hydration スクリプトは同一のものを使用。
