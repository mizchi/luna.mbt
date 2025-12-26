---
title: Stella
---

# Stella

Stella は Luna の Web Components ビルドシステムです。MoonBit コンポーネントを標準的な Web Components にコンパイルし、どこでも配布・埋め込み可能にします。

## 特徴

- **MoonBit から Web Components へ** - MoonBit UI コードを標準的な Custom Elements にコンパイル
- **Signal ベースのリアクティビティ** - `@wcr` ランタイムによる細粒度リアクティビティ
- **複数の配布バリアント** - 自動登録、ESM エクスポート、ローダー対応
- **ローダースクリプト** - コンポーネントを自動検出して動的に読み込み
- **iframe 埋め込み** - postMessage 通信によるサンドボックス化された埋め込み
- **SSR/Hydration 対応** - Declarative Shadow DOM に対応
- **TypeScript/React 型** - 利用者向けの型定義を生成

## クイックスタート

### 1. MoonBit でコンポーネントを作成

```moonbit
// src/counter.mbt
pub fn template(props_js : @js.Any) -> String {
  let initial = @wc.get_prop_int(props_js, "initial")
  let label = @wc.get_prop_string(props_js, "label")
  let mut html = @wc.HtmlBuilder::new(0)
  html.write_string("<div class=\"counter\">")
  html.write_string("<span class=\"label\">")
  html.write_string(label)
  html.write_string(":</span>")
  html.write_string("<span class=\"value\">")
  html.write_string(initial.to_string())
  html.write_string("</span>")
  html.write_string("<button class=\"inc\">+</button>")
  html.write_string("</div>")
  html.val
}

pub fn setup(ctx_js : @js.Any) -> @js.Any {
  let ctx = @wc.WcContext::from_js(ctx_js)
  let initial = ctx.prop_int("initial")
  let label = ctx.prop_string("label")
  let disabled = ctx.prop_bool("disabled")

  // ローカルステート
  let count = @wc.JsSignalInt::new(initial.get())

  // initial 変更時に同期
  let unsub_initial = initial.subscribe(fn() {
    count.set(initial.get())
    ctx.set_text(".value", count.get().to_string())
  })

  // label をバインド
  let unsub_label = ctx.bind(".label", fn() { label.get() + ":" })

  // disabled 属性をバインド
  let unsub_dec = ctx.bind_attr(".dec", "disabled", disabled.to_any())
  let unsub_inc = ctx.bind_attr(".inc", "disabled", disabled.to_any())

  // イベントハンドラ
  let unsub_click = ctx.on(".inc", "click", fn() {
    count.set(count.get() + 1)
    ctx.set_text(".value", count.get().to_string())
    ctx.emit("change", count.get())
  })

  @wc.wrap_cleanup(fn() {
    unsub_initial()
    unsub_label()
    unsub_dec()
    unsub_inc()
    unsub_click()
  })
}
```

### 2. コンポーネント設定を作成

```json
// counter.wc.json
{
  "tag": "x-counter",
  "module": "./counter.mbt.js",
  "attributes": [
    { "name": "initial", "type": "int", "default": 0 },
    { "name": "label", "type": "string", "default": "Count" },
    { "name": "disabled", "type": "bool", "default": false }
  ],
  "shadow": "open",
  "styles": ":host { display: inline-block; }"
}
```

### 3. ビルドとバンドル

```bash
# MoonBit を JS にビルド
moon build --target js

# ラッパーを生成
stella build counter.wc.json -o dist/.tmp/x-counter-wrapper.js

# esbuild でバンドル（bundle.js サンプル参照）
```

### 4. HTML で使用

```html
<x-counter initial="5" label="Score"></x-counter>
<script type="module" src="./x-counter.js"></script>
```

## 設定

### stella.config.json

コンポーネント配布用のメイン設定ファイル:

```json
{
  "tag": "x-counter",
  "publicPath": "https://cdn.example.com/components",
  "attributes": [
    { "name": "initial", "type": "int", "default": 0 },
    { "name": "label", "type": "string", "default": "Count" },
    { "name": "disabled", "type": "bool", "default": false }
  ],
  "events": [
    { "name": "change", "detail": { "value": "number" } }
  ],
  "slot": false,
  "ssr": { "enabled": false },
  "loader": { "enabled": true },
  "iframe": { "enabled": true, "resizable": true },
  "demo": {
    "enabled": true,
    "title": "x-counter Demo",
    "description": "A counter Web Component"
  },
  "cors": { "allowedOrigins": ["*"] }
}
```

### 属性型

| Type | MoonBit 型 | HTML 例 |
|------|------------|---------|
| `string` | `String` | `label="Score"` |
| `int` | `Int` | `initial="42"` |
| `float` | `Double` | `ratio="0.5"` |
| `bool` | `Bool` | `disabled` (存在 = true) |

## 出力バリアント

Stella は3つの JavaScript バリアントを生成します:

### 1. 自動登録 (`x-counter.js`)

読み込み時にカスタム要素を自動登録します。

```html
<script type="module" src="./x-counter.js"></script>
<x-counter initial="10"></x-counter>
```

### 2. ESM エクスポート (`x-counter-define.js`)

手動登録用にクラスをエクスポートします。

```javascript
import { XCounter, register } from './x-counter-define.js';

// オプション A: デフォルトタグ名で登録
register();

// オプション B: カスタムタグ名で登録
register('my-counter');

// オプション C: クラスを直接使用
customElements.define('custom-counter', XCounter);
```

### 3. Loadable (`x-counter-loadable.js`)

ローダーと SSR ハイドレーション用。

```javascript
import { load, hydrate } from './x-counter-loadable.js';

// 登録して既存の全要素をハイドレート
const count = load();
console.log(`${count} 要素をハイドレートしました`);

// 特定のコンテナをハイドレート
hydrate(document.getElementById('container'));
```

## ローダー

ローダースクリプトはコンポーネントを自動検出して動的に読み込みます。

### セットアップ

```html
<script src="https://cdn.example.com/components/loader.js"></script>
```

### 使用方法

コンポーネントは DOM で検出されると自動的に読み込まれます:

```html
<x-counter initial="5"></x-counter>
<!-- コンポーネントは自動的に読み込まれる -->
```

### API

```javascript
// 読み込み済みコンポーネントを確認
console.log(Stella.loaded());

// 手動で読み込みをトリガー
Stella.load('x-counter');

// 利用可能なコンポーネント一覧
console.log(Stella.components());
```

### ローカルテスト

ローカル開発時はベース URL を設定:

```html
<script>window.STELLA_BASE_URL = 'http://localhost:3600';</script>
<script src="http://localhost:3600/loader.js"></script>
```

## iframe 埋め込み

クロスオリジン分離のためのサンドボックス化された埋め込み。

### セットアップ（ホストページ）

```html
<script src="https://cdn.example.com/components/x-counter-iframe.js"></script>
```

### 宣言的な使用方法

```html
<div data-stella-iframe="x-counter" data-initial="10" data-label="Score"></div>
```

### プログラム的な使用方法

```javascript
const counter = createStellaIframe('#container', {
  initial: 10,
  label: 'Score'
});

// イベントをリッスン
counter.on('change', (detail) => {
  console.log('Value:', detail.value);
});

// 属性を更新
counter.setAttr('label', 'New Label');

// 準備完了を待つ
counter.on('ready', () => {
  console.log('コンポーネント読み込み完了');
});
```

### ローカルテスト

```javascript
const counter = createStellaIframe('#container', {
  initial: 0,
  baseUrl: 'http://localhost:3600'  // ローカル開発用にオーバーライド
});
```

## MoonBit Context API

### WcContext メソッド

| メソッド | 説明 |
|---------|------|
| `ctx.prop_int(name)` | Int 型の prop を Signal として取得 |
| `ctx.prop_string(name)` | String 型の prop を Signal として取得 |
| `ctx.prop_bool(name)` | Bool 型の prop を Signal として取得 |
| `ctx.bind(selector, getter)` | テキストコンテンツを getter にバインド |
| `ctx.bind_attr(selector, attr, signal)` | 属性を Signal にバインド |
| `ctx.set_text(selector, text)` | テキストコンテンツを直接設定 |
| `ctx.on(selector, event, handler)` | イベントリスナーを追加 |
| `ctx.emit(event, value)` | カスタムイベントを発火 |
| `ctx.on_cleanup(fn)` | クリーンアップ関数を登録 |

### JsSignal API

```moonbit
let count = ctx.prop_int("count")

// 値を取得
let current = count.get()

// 値を設定
count.set(10)

// 更新
count.update(fn(n) { n + 1 })

// 変更を購読
let unsub = count.subscribe(fn() {
  println("count changed!")
})

// Any に変換（bind_attr 用）
let any_signal = count.to_any()
```

## 生成されるファイル

| ファイル | 説明 |
|---------|------|
| `x-counter.js` | 自動登録バリアント |
| `x-counter-define.js` | ESM エクスポートバリアント |
| `x-counter-loadable.js` | Loadable/hydration バリアント |
| `x-counter.d.ts` | TypeScript 型定義 |
| `x-counter.react.d.ts` | React JSX 型 |
| `loader.js` | コンポーネントローダースクリプト |
| `x-counter-iframe.html` | iframe 埋め込みページ |
| `x-counter-iframe.js` | ホストページ用 iframe ヘルパー |
| `_headers` | CORS ヘッダー（Cloudflare/Netlify） |
| `index.html` | デモページ |
| `embed.html` | 埋め込みドキュメント |

## TypeScript での使用

### バニラ TypeScript

```typescript
import type { XCounter, XCounterProps } from './x-counter';

const counter = document.querySelector('x-counter') as XCounter;
counter.addEventListener('change', (e) => {
  console.log('Value:', e.detail.value);
});
```

### React

型への参照を追加:

```typescript
// global.d.ts
/// <reference path="./x-counter.react.d.ts" />
```

JSX で使用:

```tsx
function App() {
  return (
    <x-counter
      initial={5}
      label="Score"
      onChange={(e) => console.log(e.detail.value)}
    />
  );
}
```

## SSR / Hydration

Stella は SSR 用の Declarative Shadow DOM をサポート:

```html
<x-counter initial="5" label="Score">
  <template shadowrootmode="open">
    <style>/* コンポーネントスタイル */</style>
    <div class="counter">
      <span class="label">Score:</span>
      <span class="value">5</span>
      <button class="inc">+</button>
    </div>
  </template>
</x-counter>
<script type="module" src="./x-counter.js"></script>
```

コンポーネントは既存の Shadow DOM を検出し、置き換えずにハイドレートします。

## CLI リファレンス

```bash
# Web Component ラッパーを生成
stella build <config.json> [options]
  -o, --output <path>  出力ファイルパス
  -h, --help           ヘルプを表示

# 新規コンポーネントテンプレートを作成
stella init <component-name>
  基本構造を持つ <name>.wc.json を作成

# 例
stella build counter.wc.json -o dist/x-counter.js
stella init my-widget
```

## サンプルプロジェクト

`examples/stella-component/` に以下を含む完全なサンプルがあります:

- MoonBit カウンターコンポーネント
- フルビルドパイプライン
- Playwright E2E テスト（20テスト）
- デモページ

```bash
cd examples/stella-component
npm install
npm run build
npm run dev    # localhost:3600 でプレビュー
npm test       # Playwright テストを実行
```

## 関連項目

- [Luna Core](/ja/luna/) - リアクティビティシステム
- [Sol Framework](/ja/sol/) - フルスタック SSR
- [Astra SSG](/ja/astra/) - 静的サイト生成
