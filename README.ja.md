# MoonBit UI Library

[Solid.js](https://www.solidjs.com/) にインスパイアされた Fine-Grained Reactivity を備えた MoonBit 用 UI ライブラリです。

## 機能

- **Fine-Grained Reactivity** - 自動依存関係追跡を備えた Signal ベースのリアクティブプリミティブ (`Signal`, `effect`, `memo`)
- **SSR (Server-Side Rendering)** - HTML 文字列へのレンダリング
- **Hydration** - SSR コンテンツへのインタラクティビティ復元
- **JSX/TSX サポート** - `@mizchi/ui` npm パッケージ経由で JSX 構文を使用可能
- **マルチターゲット対応** - コアの Signal は js, native, wasm, wasm-gc で動作

## インストール

### MoonBit

```json
// moon.mod.json
{
  "deps": {
    "mizchi/ui": "0.1.0"
  }
}
```

### npm (JSX/TSX 用)

```bash
npm install @mizchi/ui
```

## ターゲットサポート

| パッケージ | js | native | wasm | wasm-gc |
|-----------|:--:|:------:|:----:|:-------:|
| `mizchi/ui` (コア) | ✅ | ✅ | ✅ | ✅ |
| `mizchi/ui/ssr` | ✅ | ✅ | ✅ | ✅ |
| `mizchi/ui/dom` | ✅ | - | - | - |

- **コア (`mizchi/ui`)**: Signal, VNode, リアクティブプリミティブ - 全ターゲット対応
- **SSR (`mizchi/ui/ssr`)**: サーバーサイドレンダリング - 全ターゲット対応
- **DOM (`mizchi/ui/dom`)**: ブラウザ DOM レンダリングと Hydration - JavaScript のみ

## 使い方

### MoonBit - Signal

```moonbit
// Signal を作成
let count = @ui.signal(0)

// 依存関係を自動追跡する effect を作成
let _ = @ui.effect(fn() {
  println("Count: " + count.get().to_string())
})

// 更新すると effect が発火
count.set(1)  // 出力: Count: 1
```

### MoonBit - VNode と SSR

```moonbit
// Virtual DOM を構築
let vnode = @ui.vdiv(
  [@ui.vclass("container")],
  [
    @ui.vh1([], [@ui.vtext("Hello")]),
    @ui.vp([], [@ui.vtext_dyn(fn() { count.get().to_string() })]),
  ]
)

// HTML 文字列にレンダリング
let html = @ssr.render_to_string(vnode)

// Hydration マーカー付きでレンダリング
let html_with_markers = @ssr.render_to_string_with_hydration(vnode)
```

### MoonBit - DOM レンダリング

```moonbit
// DOM にレンダリング（JavaScript ターゲットのみ）
let container = @js_dom.document().getElementById("app")
match container {
  Some(el) => @dom.render_vnode(el, vnode)
  None => ()
}

// または SSR コンテンツを Hydrate
match container {
  Some(el) => {
    let result = @dom.hydrate(el, vnode)
    // 結果を処理...
  }
  None => ()
}
```

### TypeScript/JSX

```tsx
// tsconfig.json
{
  "compilerOptions": {
    "jsx": "react-jsx",
    "jsxImportSource": "@mizchi/ui"
  }
}
```

```tsx
import { createSignal, get, set } from "@mizchi/ui";
import { render } from "@mizchi/ui/dom";

function Counter() {
  const count = createSignal(0);
  return (
    <div>
      <p>Count: {() => get(count)}</p>
      <button onClick={() => set(count, get(count) + 1)}>
        Increment
      </button>
    </div>
  );
}

const container = document.getElementById("app")!;
render(container, <Counter />);
```

## 開発

```bash
# 依存関係をインストール
pnpm install

# 全テストを実行
just test

# MoonBit テストのみ実行
just test-moonbit

# Node.js テストのみ実行
just test-node

# ビルド
just build

# コードフォーマット
just fmt
```

## プロジェクト構成

```
src/
├── *.mbt           # コア: Signal, effect, memo（全ターゲット）
├── ssr/            # SSR レンダリング（全ターゲット）
├── dom/            # DOM レンダリング & Hydration（js のみ）
├── js_api/         # JavaScript API エクスポート
└── examples/       # サンプルコード

packages/ui/        # npm パッケージ (@mizchi/ui)
├── index.js        # コアエクスポート
├── dom.js          # DOM レンダリング
├── jsx-runtime.js  # JSX ランタイム
└── *.d.ts          # TypeScript 型定義
```

## ライセンス

MIT
