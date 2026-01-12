# Luna Components

APG (ARIA Authoring Practices Guide) 準拠のアクセシブルなUIコンポーネント。

## パッケージ構成

```
src/components/
├── headless/           # ヘッドレスコンポーネント (mizchi/luna/components/headless)
│   ├── aria.mbt        # ARIA属性ヘルパー
│   ├── helpers.mbt     # イベントハンドラー等
│   └── switch.mbt      # ヘッドレスSwitch
├── default/            # スタイル付きコンポーネント (mizchi/luna/components/default)
│   ├── switch.mbt      # デフォルトSwitch
│   ├── theme.mbt       # CSS抽出API
│   └── themes/         # CSSファイル
│       ├── switch.css
│       └── index.css
└── *.mbt               # 既存コンポーネント (mizchi/luna/components)
```

## 使い方

### ヘッドレス（CSS framework agnostic）

Tailwind CSS など任意のCSSフレームワークと組み合わせて使用:

```moonbit
import mizchi/luna/components/headless as @headless

fn my_switch() -> @luna.Node[@js.Any] {
  let on = @signal.signal(false)
  let props = @headless.use_switch(on, aria_label="Enable feature")

  @luna.h("button",
    props.attrs + [
      ("class", @luna.attr_static("relative inline-flex h-6 w-11 rounded-full bg-gray-200")),
    ],
    [
      @luna.h("span", [
        ("class", @luna.attr_static("inline-block h-4 w-4 rounded-full bg-white")),
      ], []),
    ]
  )
}
```

### デフォルトスタイル付き

すぐに使えるスタイル付きコンポーネント:

```moonbit
import mizchi/luna/components/default as @default

fn my_switch() -> @luna.Node[@js.Any] {
  let on = @signal.signal(true)
  @default.switch(on, aria_label="Enable notifications", [@luna.text("Notifications")])
}
```

CSS を `<link>` で読み込む:

```html
<link rel="stylesheet" href="path/to/themes/index.css">
```

または MoonBit から CSS を抽出:

```moonbit
// 全コンポーネントのCSS
let css = @default.generate_theme_css()

// 個別コンポーネント
let switch_css = @default.switch_css()

// CSS Variables 付き
let full_theme = @default.generate_full_theme()
```

## CSS Variables

デフォルトテーマはCSS Variablesでカスタマイズ可能:

```css
:root {
  --switch-track-off: #d1d5db;
  --switch-track-on: #3b82f6;
  --accent: #3b82f6;
}
```

## BEM クラス名規約

デフォルトコンポーネントは BEM 命名規則を使用:

- `.switch` - ルート要素
- `.switch__track` - トラック
- `.switch__thumb` - スライドするつまみ
- `.switch__icon` - アイコン
- `.switch__label` - ラベル

## Data 属性

状態に応じてdata属性が付与され、CSSセレクタで使用可能:

- `[data-state="on"]` / `[data-state="off"]` - 状態
- `[data-disabled]` - 無効状態

```css
.switch[data-state="on"] .switch__track {
  background: var(--switch-track-on);
}
```
