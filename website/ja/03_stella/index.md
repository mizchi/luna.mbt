---
title: Stella
---

# Stella

StellaはLunaのWeb Componentsビルドシステムです。MoonBitコンポーネントを標準的なWeb Componentsにコンパイルし、どこでも配布・埋め込み可能にします。

## 特徴

- **MoonBitからWeb Componentsへ** - MoonBit UIコードを標準的なCustom Elementsにコンパイル
- **Signalベースのリアクティビティ** - `@luna_ui/wcr`ランタイムによるfine-grained reactivity
- **複数の配布バリアント** - 自動登録、ESMエクスポート、ローダー対応
- **ローダースクリプト** - コンポーネントを自動検出して動的に読み込み
- **SSR/Hydration対応** - Declarative Shadow DOMに対応
- **TypeScript/React型** - 利用者向けの型定義を生成

## npmパッケージ

| パッケージ | 説明 |
|-----------|------|
| `@luna_ui/stella` | Web ComponentsジェネレーターCLI |
| `@luna_ui/wcr` | Web Componentsランタイム（Signal, effect） |

## クイックスタート

### 1. MoonBitでコンポーネントを作成

```moonbit
// src/counter.mbt

pub fn template(props_js : @js.Any) -> String {
  let initial = get_prop_int(props_js, "initial")
  "<div class=\"counter\"><span class=\"value\">" + initial.to_string() + "</span></div>"
}

pub fn setup(ctx_js : @js.Any) -> @js.Any {
  let ctx = @wc.WcContext::from_js(ctx_js)
  let initial = ctx.prop_int("initial")

  let count = { val: initial.get() }

  let unsub = ctx.on(".value", "click", fn() {
    count.val = count.val + 1
    trigger_update(ctx_js, ".value", count.val.to_string())
  })

  wrap_cleanup(fn() { unsub() })
}
```

### 2. コンポーネント設定を作成

```json
// counter.wc.json
{
  "tag": "x-counter",
  "module": "./counter.mbt.js",
  "attributes": [
    { "name": "initial", "type": "int", "default": 0 }
  ],
  "shadow": "open",
  "styles": ":host { display: inline-block; }"
}
```

### 3. ビルドとバンドル

```bash
# MoonBitをJSにビルド
moon build --target js

# ラッパーを生成
npx @luna_ui/stella build counter.wc.json -o dist/x-counter.js
```

### 4. HTMLで使用

```html
<x-counter initial="5"></x-counter>
<script type="module" src="./x-counter.js"></script>
```

## MoonBitパッケージ設定

```json
// moon.pkg.json
{
  "import": [
    { "path": "mizchi/luna/stella/component", "alias": "wc" },
    { "path": "mizchi/js", "alias": "js" }
  ],
  "link": {
    "js": {
      "exports": ["setup", "template"],
      "format": "esm"
    }
  }
}
```

## 属性型

| Type | MoonBit型 | HTML例 |
|------|----------|--------|
| `string` | `String` | `label="Score"` |
| `int` | `Int` | `initial="42"` |
| `float` | `Double` | `ratio="0.5"` |
| `bool` | `Bool` | `disabled` (存在 = true) |

## Context API

| メソッド | 説明 |
|---------|------|
| `ctx.prop_int(name)` | Int型のprop Signalを取得 |
| `ctx.prop_string(name)` | String型のprop Signalを取得 |
| `ctx.prop_bool(name)` | Bool型のprop Signalを取得 |
| `ctx.bind(selector, getter)` | テキストを動的にバインド |
| `ctx.bind_attr(selector, attr, signal)` | 属性をSignalにバインド |
| `ctx.on(selector, event, handler)` | イベントリスナーを追加 |

## 出力バリアント

| ファイル | 説明 |
|---------|------|
| `x-counter.js` | 自動登録バリアント |
| `x-counter-define.js` | ESMエクスポートバリアント |
| `x-counter-loadable.js` | Loadable/hydrationバリアント |
| `x-counter.d.ts` | TypeScript型定義 |
| `x-counter.react.d.ts` | React JSX型 |

## SSR / Hydration

Declarative Shadow DOMによるSSRをサポート：

```html
<x-counter initial="5">
  <template shadowrootmode="open">
    <div class="counter"><span class="value">5</span></div>
  </template>
</x-counter>
<script type="module" src="./x-counter.js"></script>
```

## 関連項目

- [Luna UI](/ja/luna/) - リアクティビティシステム
- [Sol Framework](/ja/sol/) - フルスタックSSR
- [Astra SSG](/ja/astra/) - 静的サイト生成
