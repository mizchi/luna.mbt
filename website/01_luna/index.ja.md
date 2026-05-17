---
title: Luna
---

# Luna

MoonBit で書かれた fine-grained reactive UI プリミティブ。 mooncake `mizchi/luna` と npm `@luna_ui/luna` の両方で配布される。 同じ runtime が TypeScript の JSX コンポーネントも、 MoonBit から直接組み立てる VNode も支える。

## 何を提供するか

- **Signals** — read / write / subscribe を持ち、 依存は自動で追跡する reactive primitive。 `effect`, `memo`, `batch`, `untracked`, `createRoot`, owner ごとの cleanup まで揃っている。
- **VNode + 局所 DOM 更新** — サーバー側で型付きの `Node[E]` ツリーを組み、 クライアントで live DOM にバインドする。 Signal が変わると、 その signal を読んでいる node だけが再評価される。 ツリー全体の diff は行わない。
- **Declarative Shadow DOM SSR** — Web Component を `<wc-* luna:wc-url=… luna:wc-state=… luna:wc-trigger=…>` 形式でサーバー render し、 任意で `<template shadowrootmode="open">` を埋め込める。
- **Islands ローダー (~1.1 KB)** — 同梱の `wc-loader.js` (`@luna_ui/luna-loader`) が `[luna:wc-url]` を scan し、 trigger 別 (`load` / `idle` / `visible` / `media:(query)` / `none`) に dispatch、 モジュールの `export default function hydrate(element, state, name)` を呼ぶ。
- **2 つの記述面** — TypeScript の JSX (`@luna_ui/luna`) でも、 MoonBit の `@luna.h` / `@luna.signal` でも書ける。 render pipeline は共通。

## 30 秒で書ける Counter

### TypeScript (JSX)

```typescript
import { createSignal, render } from '@luna_ui/luna';

const [count, setCount] = createSignal(0);

render(document.getElementById('app')!, () => (
  <button onClick={() => setCount(c => c + 1)}>
    Count: {count()}
  </button>
));
```

### MoonBit

```moonbit
let count = @luna.signal(0)
let on_inc = @luna.handler(fn(_) { count.set(count.get() + 1) })

let node : @luna.Node[Unit, String] = @luna.h(
  "button",
  [("onClick", @luna.attr_handler(on_inc))],
  [@luna.text_dyn(fn() { "Count: " + count.get().to_string() })],
)
```

## Island を一目で

サーバーが普通の Web Component 要素を出力し、 残りは loader が処理する。 `customElements.define()` の登録は不要 — loader は `[luna:wc-url]` 属性で要素を拾うので、 タグが Custom Element として登録されているかどうかには依存しない。

```html
<wc-counter
  luna:wc-url="/static/wc-counter.js"
  luna:wc-state='{"initial":0}'
  luna:wc-trigger="visible">
  <template shadowrootmode="open">
    <button>Count: 0</button>
  </template>
</wc-counter>
```

```typescript
// /static/wc-counter.js
import { createSignal, render } from '@luna_ui/luna';

export default function hydrate(element: Element, state: { initial: number }) {
  const [count, setCount] = createSignal(state.initial);
  render(element, () => (
    <button onClick={() => setCount(c => c + 1)}>Count: {count()}</button>
  ));
}
```

## 周辺パッケージ

- [`@luna_ui/components`](https://www.npmjs.com/package/@luna_ui/components) — WAI-ARIA APG 準拠の headless + styled コンポーネント (tabs / dialog / slider など)
- [`mizchi/sol`](../sol/) / [`@luna_ui/sol`](https://www.npmjs.com/package/@luna_ui/sol) — Mars 系 SSR フレームワーク、 file-based routing 対応。 型付き `ComponentRef` から Luna の island を直接生成する
- [`mizchi/astra`](../astra/) / [`@luna_ui/astra`](https://www.npmjs.com/package/@luna_ui/astra) — 同じ Mars runtime で動く、 mountable な SSG middleware
- [`@luna_ui/luna-loader`](https://www.npmjs.com/package/@luna_ui/luna-loader) — WC hydration loader を単体 artifact として配布したもの (Sol と Astra は自動で inject する)
- [`@luna_ui/stella`](https://www.npmjs.com/package/@luna_ui/stella) — SSR Suspense 用の streaming / shard helper

## インストール

### MoonBit (mooncake)

```jsonc
// moon.mod.json
{ "deps": { "mizchi/luna": "0.23.0" } }
```

### TypeScript (npm)

```sh
pnpm add @luna_ui/luna
```

### プロジェクト初期化

```sh
npx @luna_ui/luna new myapp        # TSX テンプレート
npx @luna_ui/luna new myapp --mbt  # MoonBit テンプレート
```

## この先

- [Quick Start](/ja/luna/quick-start/) — 5 分で初ページが動くまで
- [Why Luna](/ja/luna/why-luna/) — React / Svelte / Solid と比較した設計の立ち位置
- [Tutorial: JavaScript](/ja/luna/tutorial-js/) — signals → effects → islands、 JSX 表面
- [Tutorial: MoonBit](/ja/luna/tutorial-moonbit/) — 同じ流れを `@luna.h` / `@luna.signal` で
- [API リファレンス: JavaScript](/ja/luna/api-js/) / [MoonBit](/ja/luna/api-moonbit/)
- [Deep Dive](/ja/luna/deep-dive/) — VNode 表現、 hydration の内部、 signal graph

モノレポのソースは [github.com/mizchi/luna.mbt](https://github.com/mizchi/luna.mbt)。
