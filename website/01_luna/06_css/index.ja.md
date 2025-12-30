---
title: CSS Utilities
---

# CSS Utilities

Luna は MoonBit アプリケーション向けのゼロクライアントサイドランタイム CSS ユーティリティを提供します。

## 概要

Luna CSS は**同一のクラス名**を生成する2つのメカニズムを提供します：

1. **MoonBit ランタイム** (`@css`): SSR 時にクラス名を生成
2. **静的抽出** (`luna css extract`): ビルド時に `.mbt` ファイルから CSS を抽出

両方とも DJB2 ハッシュを使用して決定論的なクラス名を生成し、一貫性を保証します。

## 動作の仕組み

```
ビルド時                                ランタイム（ブラウザ）
──────────────────────────────          ──────────────────────────────
.mbt ファイル                           HTML: <div class="_z5et">
    │                                   CSS:  ._z5et{display:flex}
    ▼
luna css extract → CSS ファイル          CSS 生成コードなし！
    │
@css.css("display", "flex")
    ▼
"_z5et" を返す
```

## 基本的な使い方

### MoonBit API

```moonbit
// 単一プロパティ
let flex_class = @css.css("display", "flex")  // "_z5et"

// 複数プロパティ
let card = @css.styles([
  ("display", "flex"),
  ("padding", "1rem"),
])  // "_z5et _8ktnx"

// 疑似クラス
let hover_bg = @css.hover("background", "#2563eb")

// メディアクエリ
let responsive = @css.at_md("padding", "2rem")

// 要素で使用
div(class=flex_class, [...])
```

### Vite プラグイン（推奨）

Tailwind のように CSS をインポート：

```typescript
// vite.config.ts
import { lunaCss } from "@luna_ui/luna/vite-plugin";

export default defineConfig({
  plugins: [
    lunaCss({
      src: ["src"],       // .mbt ファイルを含むソースディレクトリ
      verbose: true,
    }),
  ],
});
```

```typescript
// main.ts
import "virtual:luna.css";  // 全ての抽出された CSS
```

### CLI コマンド

```bash
# 全 CSS を抽出
luna css extract src -o dist/styles.css

# ディレクトリ単位で分割（コード分割用）
luna css extract src --split-dir --output-dir dist/css

# HTML に注入
luna css inject index.html --src src
```

## Vite プラグインオプション

```typescript
interface LunaCssPluginOptions {
  src?: string | string[];     // ソースディレクトリ
  split?: boolean;             // ディレクトリ単位の分割を有効化
  sharedThreshold?: number;    // 共通 CSS の最小使用回数（デフォルト: 3）
  verbose?: boolean;           // ログ出力を有効化
}
```

### 仮想モジュール

| モジュール | 説明 |
|-----------|------|
| `virtual:luna.css` | 全ての抽出された CSS |
| `virtual:luna-shared.css` | 共通 CSS のみ（split モード） |
| `virtual:luna-chunk/{dir}.css` | ディレクトリ単位の CSS（split モード） |

### Split モード

コード分割を行う大規模アプリケーション向け：

```typescript
lunaCss({
  src: ["src"],
  split: true,
  sharedThreshold: 3,  // 3回以上使用 → 共通 CSS
})
```

```typescript
// 共通 + ページ固有の CSS をインポート
import "virtual:luna-shared.css";
import "virtual:luna-chunk/todomvc.css";
```

## ベストプラクティス

### 1. 文字列リテラルを使用

静的抽出はリテラルでのみ動作します：

```moonbit
// ✓ 良い - 抽出可能
@css.css("display", "flex")

// ✗ 悪い - 抽出不可
let prop = "display"
@css.css(prop, "flex")
```

非リテラル引数を使用した場合：
- 静的抽出では検出できない
- MoonBit ランタイムはクラス名を生成する
- しかし CSS ルールは抽出ファイルに含まれない
- 結果：要素にクラスはあるが、対応する CSS がない

### 2. CSS は SSR コードで使用

ゼロランタイムオーバーヘッドのため：

```moonbit
// ✓ 良い - SSR コンポーネント（サーバーサイドのみ）
fn my_component() -> @static_dom.Node {
  div(class=@css.css("display", "flex"), [...])
}

// ✗ 避ける - Island コンポーネント（ブラウザで実行）
fn my_island() -> @luna.Node[Unit] {
  // @css モジュールがクライアントバンドルに含まれてしまう！
  div(class=@css.css("display", "flex"), [...])
}

// ✓ Island では事前計算されたクラス文字列を使用
fn my_island() -> @luna.Node[Unit] {
  div(class="_z5et", [...])  // @css インポート不要
}
```

**理由**: `@static_dom.Node` コンポーネントはサーバーでのみ実行されます。`@luna.Node` コンポーネントはブラウザで実行されるため、`@css` をインポートすると CSS 生成コードがクライアントバンドルに含まれます。

### 3. Island での動的スタイリング

```moonbit
// クラス名の切り替え
let class_name = if is_active.get() { "_active" } else { "_inactive" }
div(class=class_name, [...])

// CSS カスタムプロパティ
div(style="--color: " + color.get(), [...])

// 動的な値にはインラインスタイル
div(style="transform: translateX(" + x.get().to_string() + "px)", [...])
```

## 開発モード

開発中のインスタントフィードバック用：

```typescript
import { css, hover } from "@luna_ui/luna/css/runtime";

// 動的に CSS を生成し、コンソールに警告を出力
const cls = css("display", "flex");
// Console: [luna-css] Generated at runtime: ._z5et{display:flex}
//          → Run 'luna css extract' to pre-generate
```

> **注意**: 開発用ランタイムは開発中のみ使用し、本番環境では使用しないでください。

## API リファレンス

### ベーススタイル

| 関数 | 戻り値 | 例 |
|-----|--------|-----|
| `css(prop, val)` | クラス名 | `"_z5et"` |
| `styles(pairs)` | スペース区切り | `"_z5et _abc"` |
| `combine(classes)` | 結合 | `"_z5et _abc"` |

### 疑似クラス

| 関数 | セレクタ |
|-----|----------|
| `on(pseudo, prop, val)` | カスタム |
| `hover(prop, val)` | `:hover` |
| `focus(prop, val)` | `:focus` |
| `active(prop, val)` | `:active` |

### メディアクエリ

| 関数 | 条件 |
|-----|------|
| `media(cond, prop, val)` | カスタム |
| `at_sm(prop, val)` | `min-width: 640px` |
| `at_md(prop, val)` | `min-width: 768px` |
| `at_lg(prop, val)` | `min-width: 1024px` |
| `at_xl(prop, val)` | `min-width: 1280px` |
| `dark(prop, val)` | `prefers-color-scheme: dark` |

### 生成（SSR のみ）

| 関数 | 説明 |
|-----|------|
| `generate_css()` | ベーススタイルのみ（`css()`, `styles()`） |
| `generate_full_css()` | 全スタイル（ベース + 疑似 + メディア） |
| `reset_all()` | 全レジストリをクリア（テスト用） |

出力例：
```css
/* generate_css() */
._z5et{display:flex}

/* generate_full_css() */
._z5et{display:flex}
._1i41w:hover{border-color:#DB7676}
@media(min-width:768px){._abc{padding:2rem}}
```

## 関連項目

- [Signals API](/ja/luna/api-js/signals/) - リアクティブ状態管理
- [Islands](/ja/luna/api-js/islands/) - Island アーキテクチャ
