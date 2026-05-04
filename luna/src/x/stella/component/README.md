# stella/component - Web Components for MoonBit

MoonBitでWeb Componentsを実装するためのモジュール。

## 概要

このモジュールは以下を提供します：

1. **コード生成** (`codegen.mbt`) - MoonBitメタ情報からJS wrapperを生成
2. **Context API** (`context.mbt`) - setup関数で使うFFIとラッパー型

## ビルドフロー

```
┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│  counter.mbt     │     │ counter.wc.json  │     │   dist/          │
│  setup/template  │     │  tag, attrs      │     │   x-counter.js   │
└────────┬─────────┘     └────────┬─────────┘     └──────────────────┘
         │                        │                        ▲
         │ moon build             │ stella build           │
         ▼                        ▼                        │
┌──────────────────┐     ┌──────────────────┐              │
│ counter.mbt.js   │────▶│  JS Wrapper      │──────────────┘
│ (MoonBit → JS)   │     │  + Signal連携    │
└──────────────────┘     └──────────────────┘
```

## MoonBit側の実装パターン

### 基本構造

```moonbit
// 1. template関数 - 初期HTMLを返す（オプション）
pub fn template(props_js : @js.Any) -> String {
  let value = get_prop_int(props_js, "value")
  "<div class=\"value\">" + value.to_string() + "</div>"
}

// 2. setup関数 - イベント・Signalを接続（必須）
pub fn setup(ctx_js : @js.Any) -> @js.Any {
  let ctx = @wc.WcContext::from_js(ctx_js)

  // props は Signal として受け取る
  let value = ctx.prop_int("value")

  // DOM バインディング
  let unbind = ctx.bind(".value", fn() { value.get().to_string() })

  // イベントハンドラ
  let unbind_click = ctx.on(".btn", "click", fn() {
    value.set(value.get() + 1)
  })

  // クリーンアップ関数を返す
  wrap_cleanup(fn() {
    unbind()
    unbind_click()
  })
}
```

### Context API

| メソッド | 説明 |
|---------|------|
| `ctx.prop_int(name)` | Int型のprop Signalを取得 |
| `ctx.prop_string(name)` | String型のprop Signalを取得 |
| `ctx.prop_bool(name)` | Bool型のprop Signalを取得 |
| `ctx.bind(selector, getter)` | テキストを動的にバインド |
| `ctx.bind_attr(selector, attr, signal)` | 属性をSignalにバインド |
| `ctx.on(selector, event, handler)` | イベントリスナーを追加 |
| `ctx.on_cleanup(fn)` | クリーンアップ関数を登録 |

### JsSignal API

```moonbit
let count = ctx.prop_int("count")

// 値の取得
let current = count.get()

// 値の設定
count.set(10)

// 更新
count.update(fn(n) { n + 1 })

// 購読
let unsub = count.subscribe(fn() {
  println("count changed!")
})
```

## 設定ファイル (*.wc.json)

```json
{
  "tag": "x-counter",
  "module": "./counter.mbt.js",
  "attributes": [
    { "name": "initial", "type": "int", "default": 0 },
    { "name": "label", "type": "string", "default": "" },
    { "name": "disabled", "type": "bool", "default": false }
  ],
  "shadow": "open",
  "styles": ":host { display: block; }"
}
```

### 属性型

| type | MoonBit型 | HTML例 |
|------|----------|--------|
| `string` | `String` | `label="Count"` |
| `int` | `Int` | `initial="42"` |
| `float` | `Double` | `ratio="0.5"` |
| `bool` | `Bool` | `disabled` (存在=true) |

## CLI使用方法

```bash
# Web Component wrapperを生成
stella build counter.wc.json -o dist/x-counter.js

# 新規コンポーネントテンプレートを作成
stella init my-widget
```

## 使用例

### 空要素（クライアントレンダリング）

```html
<x-counter initial="5" label="Score"></x-counter>
<script type="module" src="/dist/x-counter.js"></script>
```

### SSR済み（Hydration）

```html
<x-counter initial="5" label="Score">
  <template shadowrootmode="open">
    <style>:host { display: block; }</style>
    <div class="counter">
      <span class="label">Score:</span>
      <span class="value">5</span>
    </div>
  </template>
</x-counter>
<script type="module" src="/dist/x-counter.js"></script>
```

## ディレクトリ構成

```
src/stella/component/
├── moon.pkg.json      # パッケージ設定
├── types.mbt          # AttrType, ComponentMeta (コード生成用)
├── codegen.mbt        # MoonBit → JS コード生成
├── context.mbt        # WcContext, JsSignal* (FFIラッパー)
└── README.md          # このファイル
```

## サンプル

`src/examples/wc_counter/` に完全な実装例があります。

```bash
# ビルド
moon build --target js

# wrapper生成
stella build src/examples/wc_counter/counter.wc.json \
  -o src/examples/wc_counter/dist/x-counter.js

# 開発サーバー
npx vite --config src/examples/wc_counter/vite.config.ts
# → http://localhost:3500/
```
