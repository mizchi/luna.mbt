# Luna UI

> **Warning: Proof of Concept (PoC)**
>
> このプロジェクトは実験的であり、活発に開発中です。APIは予告なく変更される可能性があります。本番環境での使用は推奨しません。

[Solid.js](https://www.solidjs.com/) と [Qwik](https://qwik.dev/) にインスパイアされた Fine-Grained Reactivity と **Island Architecture** を備えた [MoonBit](https://www.moonbitlang.com/) 用 UI ライブラリです。

- **クライアントサイド**: ブラウザ DOM レンダリングとハイドレーション用に JavaScript にコンパイル
- **サーバーサイド**: 高性能 SSR のためにネイティブバックエンドで実行
- **JavaScript API**: `@luna_ui/luna` npm パッケージ経由で JavaScript/TypeScript から使用可能

## 機能

- **Fine-Grained Reactivity** - 自動依存関係追跡を備えた Signal ベースのリアクティブプリミティブ (`Signal`, `effect`, `memo`)
- **Island Architecture** - 選択的なコンポーネントローディングによる部分的ハイドレーション
- **SSR (Server-Side Rendering)** - ストリーミング対応の HTML 文字列レンダリング
- **Hydration** - SSR コンテンツへのインタラクティビティ復元（複数のトリガー戦略: load, idle, visible, media）
- **JSX/TSX サポート** - `@luna_ui/luna` npm パッケージ経由で JSX 構文を使用可能
- **マルチターゲット対応** - コアの Signal は js, native, wasm, wasm-gc で動作

## インストール

### MoonBit

```json
// moon.mod.json
{
  "deps": {
    "mizchi/luna": "0.1.0"
  }
}
```

### npm (JSX/TSX 用)

```bash
npm install @luna_ui/luna
```

## ターゲットサポート

| パッケージ | js | native | wasm | wasm-gc |
|-----------|:--:|:------:|:----:|:-------:|
| `mizchi/luna` (コア) | ✅ | ✅ | ✅ | ✅ |
| `mizchi/luna/core/render` | ✅ | ✅ | ✅ | ✅ |
| `mizchi/luna/platform/dom` | ✅ | - | - | - |

- **コア (`mizchi/luna`)**: Signal, VNode, リアクティブプリミティブ - 全ターゲット対応
- **Render (`mizchi/luna/core/render`)**: HTML 文字列レンダリング - 全ターゲット対応
- **DOM (`mizchi/luna/platform/dom`)**: ブラウザ DOM レンダリングと Hydration - JavaScript のみ

## 使い方

### MoonBit - Signal

```moonbit
// Signal を作成
let count = @signal.signal(0)

// 計算値を作成 (memo)
let doubled = @signal.memo(fn() { count.get() * 2 })

// 依存関係を自動追跡する effect を作成
let _ = @signal.effect(fn() {
  println("Count: " + count.get().to_string())
  @signal.on_cleanup(fn() { println("Cleaning up") })
})

// 更新すると effect が発火
count.set(1)  // 出力: Count: 1
count.update(fn(n) { n + 1 })  // 出力: Count: 2
```

### MoonBit - DOM レンダリング

```moonbit
fn counter_component() -> @dom.DomNode {
  let count = @signal.signal(0)
  let doubled = @signal.memo(fn() { count.get() * 2 })

  @dom.div(class="counter", [
    @dom.h2([@dom.text("Counter")]),
    @dom.p([@dom.text_dyn(fn() { "Count: " + count.get().to_string() })]),
    @dom.p([@dom.text_dyn(fn() { "Doubled: " + doubled().to_string() })]),
    @dom.div(class="buttons", [
      @dom.button(
        on=@dom.events().click(fn(_) { count.update(fn(n) { n - 1 }) }),
        [@dom.text("-")],
      ),
      @dom.button(
        on=@dom.events().click(fn(_) { count.update(fn(n) { n + 1 }) }),
        [@dom.text("+")],
      ),
      @dom.button(
        on=@dom.events().click(fn(_) { count.set(0) }),
        [@dom.text("Reset")],
      ),
    ]),
  ])
}

fn main {
  let doc = @js_dom.document()
  match doc.getElementById("app") {
    Some(el) => {
      let app = counter_component()
      @dom.render(el |> @dom.DomElement::from_jsdom, app)
    }
    None => ()
  }
}
```

### TypeScript/JSX

```tsx
// tsconfig.json
{
  "compilerOptions": {
    "jsx": "react-jsx",
    "jsxImportSource": "@luna_ui/luna"
  }
}
```

```tsx
import { createSignal, get, set } from "@luna_ui/luna";
import { render } from "@luna_ui/luna";

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

[just](https://github.com/casey/just) コマンドランナーが必要です。

```bash
# 依存関係をインストール
pnpm install

# 全 CI チェックを実行（PR 前に推奨）
just ci

# 型チェック
just check

# 全テストを実行
just test

# MoonBit テストのみ実行
just test-moonbit

# ブラウザテストを実行
just test-browser

# E2E テストを実行
just test-e2e

# ビルド
just build

# コードフォーマット
just fmt

# バンドルサイズを表示
just size

# ウォッチモード
just watch
```

## プロジェクト構成

```
src/
├── core/                      # ターゲット非依存
│   ├── signal/                # Signal プリミティブ
│   ├── vnode.mbt              # VNode 定義
│   ├── render/                # HTML 文字列レンダリング
│   ├── routes/                # ルートマッチング
│   └── serialize/             # 状態シリアライズ
├── platform/                  # プラットフォーム固有
│   ├── dom/                   # ブラウザ DOM API
│   │   ├── element/           # 低レベル DOM 操作 (render, diff, reconcile)
│   │   └── router/            # クライアントサイドルーター
│   ├── js/                    # JS 固有
│   │   └── api/               # JS 向け公開 API (@luna_ui/luna)
│   └── server_dom/            # サーバーサイド SSR ヘルパー
├── stella/                    # Shard/Island 埋め込み
├── sol/                       # SSR フレームワーク (CLI + ランタイム)
├── examples/                  # サンプルアプリケーション
└── tests/                     # テストフィクスチャ

js/
├── luna/                      # npm パッケージ (@luna_ui/luna)
└── loader/                    # Island ハイドレーションローダー (@luna_ui/luna-loader)

e2e/                           # Playwright E2E テスト
```

## Island Architecture

Luna は Island Architecture による部分的ハイドレーションをサポートしています。コンポーネントはサーバーでレンダリングされ、トリガーに基づいてクライアントで選択的にハイドレートされます:

| トリガー | 説明 |
|---------|------|
| `load` | ページロード時に即座にハイドレート |
| `idle` | ブラウザのアイドル時間にハイドレート (requestIdleCallback) |
| `visible` | 要素が表示されたときにハイドレート (IntersectionObserver) |
| `media` | メディアクエリがマッチしたときにハイドレート |
| `none` | `__LN_HYDRATE__` 経由で手動ハイドレート |

## Sol - SSR フレームワーク

Sol は Hono と統合されたビルトインの SSR フレームワークです。新規プロジェクトを作成:

```bash
just sol new myapp
```

## ライセンス

MIT
