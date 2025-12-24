# @luna_ui/wcssr

Web Components SSR runtime with functional API.

Declarative Shadow DOM を使った Web Components の SSR/Hydration ライブラリ。
MoonBit FFI から利用しやすい関数型インターフェースを提供。

## 特徴

- **サーバー/クライアント分離**: サーバー側は純粋関数のみ、DOM依存なし
- **関数型API**: クラスベースではなく、純粋なオブジェクトと関数で定義
- **CSS戦略選択可能**: inline / link / link-preload / adoptable
- **MoonBit FFI対応**: シンプルなインターフェースで外部言語から利用可能

## インストール

```bash
pnpm add @luna_ui/wcssr
```

## 使い方

### コンポーネント定義

```ts
import { defineComponent } from '@luna_ui/wcssr/client';

const Counter = defineComponent({
  name: 'my-counter',
  styles: `
    :host { display: block; padding: 16px; }
    .count { font-size: 2rem; }
  `,
  initialState: { count: 0 },
  render: (state) => `
    <div class="count">${state.count}</div>
    <button data-on-click="decrement">-</button>
    <button data-on-click="increment">+</button>
  `,
  handlers: {
    increment: (state) => ({ count: state.count + 1 }),
    decrement: (state) => ({ count: state.count - 1 }),
  },
});
```

### サーバーサイド (SSR)

```ts
import { createSSRRenderer, renderDocument } from '@luna_ui/wcssr/server';

// レンダラー作成
const renderer = createSSRRenderer({
  cssStrategy: 'link-preload',
  baseUrl: '/assets/',
});

// コンポーネントをレンダリング
const counterHtml = renderer.render(Counter, { count: 5 });

// preloadタグを取得
const preloads = renderer.getPreloadTags();

// ドキュメント生成
const html = renderDocument({
  title: 'My App',
  preloadTags: preloads,
  body: counterHtml,
  clientRuntime: '/wcssr-client.js',
});
```

### クライアントサイド (Hydration)

```ts
import { registerComponent } from '@luna_ui/wcssr/client';

// コンポーネントを登録（Hydration開始）
registerComponent(Counter);
```

## CSS戦略

| 戦略 | 用途 | 特徴 |
|------|------|------|
| `inline` | 外部配信 | 自己完結、ポータビリティ重視 |
| `link` | 一般的なSSR | ブラウザキャッシュ効く |
| `link-preload` | パフォーマンス重視 | 並列ロード |
| `adoptable` | SPA/動的生成 | メモリ効率最高 |

### 推奨

- **フレームワーク内SSR**: `link-preload`
- **外部配信ビルド**: `inline`

## イベントバインディング

`data-on-*` 属性でイベントとハンドラを紐付け:

```html
<button data-on-click="handleClick">Click</button>
<input data-on-input="handleInput" />
<form data-on-submit="handleSubmit">...</form>
```

サポートするイベント:
- `click`, `input`, `change`, `keypress`, `keydown`, `keyup`, `submit`, `focus`, `blur`

## アーキテクチャ

```
┌─────────────────────────────────────────────────────────────┐
│  ComponentDef (純粋なオブジェクト)                           │
│  ───────────────────────────────────────                    │
│  - name, styles, initialState                               │
│  - render: (state) => string                                │
│  - handlers: { [name]: (state, payload) => state }          │
└─────────────────────────────────────────────────────────────┘
                            │
            ┌───────────────┴───────────────┐
            ▼                               ▼
┌───────────────────────┐       ┌───────────────────────┐
│  Server               │       │  Client               │
│  ─────────────────    │       │  ─────────────────    │
│  createSSRRenderer()  │       │  registerComponent()  │
│  render() → HTML      │       │  → customElements     │
│  (純粋関数)            │       │  → Event binding      │
│  (DOM依存なし)         │       │  (DOM必須)            │
└───────────────────────┘       └───────────────────────┘
```

## MoonBit FFI

サーバー側は純粋関数のみなので、MoonBit から直接呼び出し可能:

```moonbit
// MoonBit側でレンダリング
fn render_counter(count: Int) -> String {
  render_component_inline(
    "my-counter",
    ":host { display: block; }",
    @json.stringify({ "count": count }),
    "<div>\{count}</div>"
  )
}
```

クライアント側は JS ランタイムが必要なため、FFI 経由で `registerComponent` を呼び出す。

## テスト

```bash
# サーバーテスト (Node.js)
pnpm test

# ブラウザテスト (Playwright)
pnpm test:browser

# ブラウザテスト (UI付き)
pnpm test:browser:ui
```

### テストカバレッジ

| テストファイル | 内容 |
|--------------|------|
| `src/server.test.ts` | SSRレンダリング、エスケープ処理 |
| `tests/client.browser.test.ts` | CSR、Hydration、イベント処理 |
| `tests/snapshot.browser.test.ts` | SSR/Hydration一致、視覚スナップショット |

### スナップショットテスト

SSR only と Hydration 後で同じ表示になることを保証:

```ts
// SSR状態のコンテンツを記録
const ssrContent = getShadowContent(el);

// Hydration
registerComponent(Counter);

// SSR と Hydration 後で同じコンテンツ
expect(getShadowContent(el)).toBe(ssrContent);

// インラインスナップショットでHTML構造を検証
expect(content).toMatchInlineSnapshot(`"<div class="count">5</div>..."`);
```

Note: 視覚的スナップショット（画像比較）は Vitest 4.0+ の `toMatchScreenshot` で対応予定。

## ファイル構成

```
src/
├── types.ts         # 型定義（共通）
├── server.ts        # SSRランタイム（純粋関数）
├── server.test.ts   # サーバーテスト
├── client.ts        # Hydrationランタイム（DOM依存）
├── server-entry.ts  # サーバー専用エントリ
├── client-entry.ts  # クライアント専用エントリ
└── index.ts         # メインエントリ
tests/
├── client.browser.test.ts    # ブラウザテスト
└── snapshot.browser.test.ts  # スナップショットテスト
```

## ライセンス

MIT
