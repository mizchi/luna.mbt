# Declarative Shadow DOM SSR 調査

## 概要

Declarative Shadow DOM (DSD) を使った SSR の現状と、Luna のアプローチとの比較。

## 結論

**DSD + SSR 対応の headless UI ライブラリは存在しない。**

- Lit SSR は DSD 対応だが、UI ライブラリではなくフレームワーク
- Radix, Headless UI, Ariakit は全て React 専用
- Vanilla UI (vanilla-primitives) は Light DOM で DSD 非対応

Luna の現行アプローチ（Light DOM + data 属性 + Vanilla JS hydration）が現実的。

## Lit SSR の実装分析

### アーキテクチャ

```
@lit-labs/ssr
├── render.ts           # エントリポイント
├── render-value.ts     # テンプレート→オペコード→HTML
├── element-renderer.ts # ElementRenderer 基底クラス
└── lit-element-renderer.ts # LitElement 用レンダラー

依存:
├── @lit-labs/ssr-dom-shim  # Node.js 用 DOM shim
├── parse5                   # HTML パーサー
└── lit-html internals       # テンプレート処理
```

### DSD 生成の核心部分

```typescript
// render-value.ts
case 'custom-element-shadow': {
  const shadowContents = instance.renderShadow(renderInfo);
  if (shadowContents !== undefined) {
    const {mode = 'open', delegatesFocus} = instance.shadowRootOptions ?? {};
    const delegatesfocusAttr = delegatesFocus ? ' shadowrootdelegatesfocus' : '';
    shadowResult.push(
      `<template shadowroot="${mode}" shadowrootmode="${mode}"${delegatesfocusAttr}>`
    );
    shadowResult.push(() => shadowContents);
    shadowResult.push('</template>');
  }
}
```

### オペコードシステム

テンプレートを parse5 でパースし、以下のオペコードに変換:

| オペコード | 役割 |
|-----------|------|
| `text` | 静的 HTML 出力 |
| `child-part` | 動的値（子要素） |
| `attribute-part` | 動的属性 |
| `custom-element-open` | CE インスタンス生成 |
| `custom-element-shadow` | DSD 生成 |
| `custom-element-close` | CE スタック pop |

### LitElementRenderer

```typescript
class LitElementRenderer extends ElementRenderer {
  renderShadow(renderInfo: RenderInfo): ThunkedRenderResult {
    const result = [];
    // 1. スタイル出力
    const styles = this.element.constructor.elementStyles;
    if (styles?.length > 0) {
      result.push('<style>');
      for (const style of styles) {
        result.push(style.cssText);
      }
      result.push('</style>');
    }
    // 2. render() 結果を出力
    result.push(() => renderValue(this.element.render(), renderInfo));
    return result;
  }
}
```

### Hydration

```javascript
// クライアント側
import '@lit-labs/ssr-client/lit-element-hydrate-support.js';
// ↑ lit より先に読み込む必要あり

// DSD はブラウザが自動で attachShadow
// Lit は既存 DOM に hydrate してイベントを接続
```

## 既存ライブラリの調査結果

| ライブラリ | DOM 方式 | SSR/DSD | 備考 |
|-----------|---------|---------|------|
| [Lit](https://lit.dev/docs/ssr/overview/) | Shadow DOM | ✅ DSD 対応 | フレームワーク、UI ライブラリではない |
| [Radix UI](https://www.radix-ui.com/) | React Virtual DOM | ❌ | React 専用 |
| [Headless UI](https://headlessui.com/) | React/Vue | ❌ | React/Vue 専用 |
| [Ariakit](https://ariakit.org/) | React | ❌ | React 専用 |
| [Vanilla UI](https://www.vanilla-ui.com/) | Light DOM | ❌ | Radix の WC 移植、SSR 言及なし |
| [vanilla-headless](https://www.npmjs.com/package/vanilla-headless) | Standard DOM | ❌ | SSR 言及なし |

## Luna vs Lit アプローチ比較

| 観点 | Lit SSR | Luna |
|------|---------|------|
| DOM モデル | Shadow DOM (DSD) | Light DOM |
| スタイル分離 | Shadow 境界 | CSS scope / data 属性 |
| SSR 出力 | `<template shadowrootmode>` | 通常 HTML + data 属性 |
| Hydration | lit-element-hydrate-support.js (~16KB) | 独自ローダー (~1KB) |
| 依存 | parse5, DOM shim, lit-html | なし |
| コンポーネント | ~数KB/component | ~500B/component |
| ブラウザ互換 | DSD ポリフィル必要 (Safari/Firefox) | 完全互換 |

## Luna の現行アプローチ

### 構造

```
SSR (MoonBit)
    ↓
<div luna:id="accordion" luna:url="./accordion.js" luna:trigger="visible">
  <div data-accordion-item data-state="open">
    <button data-accordion-trigger>Title</button>
    <div data-accordion-content>Content</div>
  </div>
</div>
    ↓
Hydration (Vanilla JS, ~500B)
```

### 利点

1. **シンプル**: DOM shim やパーサー不要
2. **軽量**: コンポーネント単位で ~500B
3. **互換性**: 全ブラウザ対応
4. **SEO**: 完全な HTML が配信される

### 欠点

1. **スタイル分離なし**: グローバル CSS / data 属性セレクタで対応
2. **A11Y 自前実装**: focus trap, keyboard navigation など

## 推奨方針

### 短期（現状維持）

- Light DOM + data 属性 + Vanilla JS hydration
- シンプルなコンポーネント（Switch, Checkbox, Accordion）はこれで十分

### 中期（A11Y ユーティリティ）

複雑な A11Y パターンを共通化:

```javascript
// js/luna/src/a11y/focus-trap.js
export function createFocusTrap(container, options) { /* ... */ }

// js/luna/src/a11y/keyboard-nav.js
export function createKeyboardNav(items, options) { /* ... */ }

// js/luna/src/a11y/live-region.js
export function announce(message, priority) { /* ... */ }
```

### 長期（検討事項）

DSD が必要になるケース:
- スタイル完全分離が必須のデザインシステム
- サードパーティ埋め込みウィジェット

その場合は Lit を部分的に採用するか、Luna 独自の DSD レンダラーを検討。

## Zag.js 調査

### 概要

[Zag.js](https://zagjs.com/) は Chakra UI チームが開発した状態機械ベースの headless UI ライブラリ。
**Vanilla JS を公式サポート**しており、Luna への組み込み候補として調査。

### バンドルサイズ (bundlephobia)

| パッケージ | gzip | minified |
|-----------|------|----------|
| `@zag-js/core` | 12.9KB | 35.8KB |
| `@zag-js/accordion` | 25.0KB | 82.4KB |
| `@zag-js/switch` | 23.6KB | 84.7KB |
| `@zag-js/dialog` | 26.5KB | 90KB+ |

**評価**: 1コンポーネントで ~25KB は Luna の軽量方針に合わない。

### アーキテクチャ

```
┌─────────────────────────────────────────┐
│  State Machine (@zag-js/core ~13KB)     │
│    - states, events, guards, actions    │
│    - XState インスパイア                │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│  Component Machine (@zag-js/accordion)  │
│    - machine定義 + connect()            │
│    - API (getRootProps, etc.)           │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│  Framework Adapter                      │
│    - React: useMachine hook             │
│    - Vanilla: VanillaMachine class      │
└─────────────────────────────────────────┘
```

### 状態機械の例 (Accordion)

```typescript
// @zag-js/accordion/src/accordion.machine.ts
const machine = createMachine({
  initialState: () => "idle",

  states: {
    idle: {
      on: {
        "TRIGGER.FOCUS": {
          target: "focused",
          actions: ["setFocusedValue"]
        },
      },
    },
    focused: {
      on: {
        "TRIGGER.CLICK": [
          {
            guard: and("isExpanded", "canToggle"),
            actions: ["collapse"]
          },
          {
            guard: not("isExpanded"),
            actions: ["expand"]
          },
        ],
        "GOTO.NEXT": { actions: ["focusNextTrigger"] },
        "GOTO.PREV": { actions: ["focusPrevTrigger"] },
        "GOTO.FIRST": { actions: ["focusFirstTrigger"] },
        "GOTO.LAST": { actions: ["focusLastTrigger"] },
        "TRIGGER.BLUR": {
          target: "idle",
          actions: ["clearFocusedValue"]
        },
      },
    },
  },

  implementations: {
    guards: {
      canToggle: ({ prop }) => !!prop("collapsible") || !!prop("multiple"),
      isExpanded: ({ context, event }) => context.get("value").includes(event.value),
    },
    actions: {
      collapse({ context, event }) { /* ... */ },
      expand({ context, event }) { /* ... */ },
    },
  },
})
```

### Vanilla JS 実装パターン

```typescript
// examples/vanilla-ts/src/switch.ts
import * as switchMachine from "@zag-js/switch"
import { Component } from "./component"
import { normalizeProps, spreadProps, VanillaMachine } from "./lib"

export class Switch extends Component<switchMachine.Props, switchMachine.Api> {
  initMachine(props) {
    return new VanillaMachine(switchMachine.machine, props)
  }

  initApi() {
    return switchMachine.connect(this.machine.service, normalizeProps)
  }

  render() {
    spreadProps(this.rootEl, this.api.getRootProps())
    spreadProps(control, this.api.getControlProps())
    spreadProps(thumb, this.api.getThumbProps())
  }
}

// 使用
const sw = new Switch(document.getElementById('switch'), { defaultChecked: true })
sw.init()  // machine.start() + subscribe
```

### spreadProps ユーティリティ

```typescript
// DOM に属性とイベントリスナーを適用
export function spreadProps(node: Element, attrs: Attrs): () => void {
  const oldAttrs = prevAttrsMap.get(node) || {}

  // イベントリスナーの差分更新
  Object.keys(oldAttrs).filter(onEvents).forEach((evt) => {
    node.removeEventListener(evt.substring(2), oldAttrs[evt])
  })
  Object.keys(attrs).filter(onEvents).forEach((evt) => {
    node.addEventListener(evt.substring(2), attrs[evt])
  })

  // 属性の差分更新
  for (const key in attrs) {
    if (attrs[key] !== oldAttrs[key]) {
      node.setAttribute(key, attrs[key])
    }
  }

  prevAttrsMap.set(node, attrs)
  return cleanup
}
```

### 評価

| 観点 | 評価 | 備考 |
|------|------|------|
| Vanilla JS 対応 | ✅ | 公式 example あり |
| SSR 対応 | △ | 初期 HTML は別途必要 |
| バンドルサイズ | ❌ | 25KB/component は重い |
| A11Y | ✅ | 完全な ARIA サポート |
| 状態管理 | ✅ | 予測可能な状態機械 |

### Luna への組み込み判断

```
❌ 直接組み込みは非推奨
  - バンドルサイズが Luna の方針に合わない
  - 1コンポーネント 25KB vs Luna 現行 500B

✅ パターンの借用は有効
  - 状態機械の設計思想
  - connect() による API 生成
  - spreadProps による差分更新
```

## Base UI 調査

### 概要

[Base UI](https://base-ui.com/) は MUI チームが開発した unstyled React コンポーネントライブラリ。
Radix, Floating UI, Material UI の作者が関与。

### 評価

```
❌ Luna には組み込めない
  - React 専用（Vanilla JS 非対応）
  - "Base UI is a library of unstyled UI components... with React"
```

## Headless UI ライブラリ比較まとめ

| ライブラリ | Framework | Vanilla JS | SSR | Bundle Size |
|-----------|-----------|------------|-----|-------------|
| [Zag.js](https://zagjs.com/) | React/Vue/Solid/Svelte | ✅ | △ | ~25KB/comp |
| [Ark UI](https://ark-ui.com/) | React/Vue/Solid/Svelte | ❌ | △ | Zag ベース |
| [Base UI](https://base-ui.com/) | React only | ❌ | ✅ | - |
| [Headless UI](https://headlessui.com/) | React/Vue | ❌ | △ | - |
| [Melt UI](https://melt-ui.com/) | Svelte only | ❌ | ✅ | 軽量 |
| [Vanilla UI](https://www.vanilla-ui.com/) | Web Components | ✅ | ❌ | - |
| **Luna 現行** | Vanilla JS | ✅ | ✅ | ~500B/comp |

## 最終推奨

### コンポーネント複雑度別アプローチ

| 複雑度 | 例 | 推奨 | サイズ |
|--------|-----|------|--------|
| 低 | Switch, Checkbox | Vanilla JS | ~500B |
| 中 | Accordion, Tabs | Vanilla JS + 共通 utils | ~1-2KB |
| 高 | Dialog, Combobox | 要検討 | 自前: 3-5KB / Zag: 25KB |

### 実装方針

1. **シンプルなコンポーネント**: 現行の Vanilla JS アプローチを継続
2. **複雑なコンポーネント**: Zag のパターンを参考に軽量版を自前実装
3. **A11Y ユーティリティ**: focus-trap, keyboard-nav を共通モジュール化

```javascript
// 将来の js/luna/src/a11y/ 構成案
├── focus-trap.js      // Dialog, Popover 用
├── keyboard-nav.js    // Menu, Listbox 用
├── live-region.js     // スクリーンリーダー通知
└── roving-tabindex.js // Tab, Radio グループ用
```

## 参考リンク

- [Lit SSR](https://lit.dev/docs/ssr/overview/)
- [Declarative Shadow DOM - Chrome](https://developer.chrome.com/docs/css-ui/declarative-shadow-dom)
- [Radix UI](https://www.radix-ui.com/)
- [Vanilla UI](https://www.vanilla-ui.com/)
- [template-shadowroot polyfill](https://github.com/nicknisi/template-shadowroot)
- [Zag.js](https://zagjs.com/)
- [Zag GitHub](https://github.com/chakra-ui/zag)
- [Zag vanilla-ts example](https://github.com/chakra-ui/zag/tree/main/examples/vanilla-ts)
- [Base UI](https://base-ui.com/)
- [Ark UI](https://ark-ui.com/)
- [Melt UI](https://melt-ui.com/)
