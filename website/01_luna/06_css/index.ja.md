---
title: CSS Utilities
---

# CSS Utilities

Luna は MoonBit アプリケーション向けのゼロランタイム CSS ユーティリティを提供します。

## 概要

Luna の CSS ユーティリティの特徴：

- **直接的な CSS API**: CSS プロパティ名をそのまま使用（`css("display", "flex")`）
- **自動重複排除**: 同じ宣言は同じクラス名を共有
- **ハッシュベースのクラス名**: 決定的な短い名前（`_z5et`, `_3pgqo`...）
- **ゼロクライアントサイドランタイム**: CSS 生成は SSR 時にのみ実行
- **オプトイン**: `@css` をインポートした場合のみバンドルに含まれる

## 基本的な使い方

### 単一プロパティ

```moonbit
// 単一の CSS プロパティ
let flex_class = @css.css("display", "flex")  // "_z5et" を返す

// 要素で使用
div(class=flex_class, [...])
```

### 複数プロパティ

```moonbit
// 複数のプロパティを一度に
let card_class = @css.styles([
  ("display", "flex"),
  ("align-items", "center"),
  ("padding", "1rem"),
])  // "_z5et _3m33u _8ktnx" を返す
```

### クラスの結合

```moonbit
let base = @css.css("display", "flex")
let center = @css.css("align-items", "center")
let combined = @css.combine([base, center])  // "_z5et _3m33u"
```

## 疑似クラス

```moonbit
// ホバー状態
let hover_bg = @css.hover("background", "#2563eb")

// フォーカス状態
let focus_outline = @css.focus("outline", "2px solid blue")

// アクティブ状態
let active_scale = @css.active("transform", "scale(0.98)")

// 汎用疑似クラス/要素
let first_margin = @css.on(":first-child", "margin-top", "0")
```

## メディアクエリ

```moonbit
// レスポンシブブレークポイント
let md_padding = @css.at_md("padding", "2rem")    // min-width: 768px
let lg_font = @css.at_lg("font-size", "1.25rem")  // min-width: 1024px

// ダークモード
let dark_bg = @css.dark("background", "#1a1a1a")

// カスタムメディアクエリ
let custom = @css.media("min-width: 1440px", "max-width", "1200px")
```

## ゼロランタイムアーキテクチャ

Luna の CSS ユーティリティは**ゼロクライアントサイドランタイム**を実現する設計です：

```
SSR フェーズ                      クライアントフェーズ
─────────────────────────        ─────────────────────────
@css.css("display", "flex")      class="_z5et"（文字列のみ）
        ↓                        クライアントバンドルに
    "_z5et" を返す                CSS コードは含まれない
        ↓
generate_full_css()
        ↓
<style>._z5et{display:flex}</style>
```

### オプトイン設計

CSS ユーティリティは `@css` をインポートした場合のみバンドルに含まれます：

```moonbit
// @css インポートなし: 44KB バンドル（CSS コードなし）
import "mizchi/luna/luna/signal"

// @css インポートあり: CSS コードが含まれる
import "mizchi/luna/luna/css"
```

## ビルドツール

### CLI コマンド

Luna は CSS 抽出と注入のための CLI コマンドを提供：

```bash
# .mbt ファイルから CSS を抽出
npx luna css extract src/examples/todomvc

# CSS を圧縮
npx luna css minify input.css -o output.min.css

# CSS を JavaScript にインライン化（ランタイム注入用）
npx luna css inline input.css -o output.js

# HTML テンプレートに CSS を注入
npx luna css inject index.html --src src/myapp
```

### Vite プラグイン

Vite での開発には Luna CSS プラグインを使用：

```typescript
// vite.config.ts
import { lunaCss } from "@luna_ui/luna/vite-plugin";

export default defineConfig({
  plugins: [
    lunaCss({
      src: ["src/examples/todomvc"],  // ソースディレクトリ
      mode: "auto",                    // "inline" | "external" | "auto"
      threshold: 4096,                 // auto モードのサイズ閾値
      verbose: true,                   // ログを有効化
    }),
  ],
});
```

プラグインの機能：
- ビルド時に `.mbt` ファイルから CSS を抽出
- HTML テンプレートに CSS を注入
- 変更を監視して HMR をトリガー

### 静的 CSS 抽出

本番ビルドでは、CSS を静的に抽出：

```bash
# ディレクトリから抽出
npx luna css extract src --output utilities.css

# 整形出力
npx luna css extract src --pretty

# クラスマッピング付き JSON 形式
npx luna css extract src --json
```

## ベストプラクティス

### 文字列リテラルを使用

静的抽出との互換性のため、常に文字列リテラルを使用：

```moonbit
// 良い例: 静的に抽出可能
@css.css("display", "flex")
@css.hover("background", "#2563eb")

// 悪い例: 抽出不可、ランタイムでのみ動作
let prop = "display"
@css.css(prop, "flex")  // 警告: 非リテラル引数
```

### CSS は SSR コードで使用

ゼロランタイムを維持するため、CSS ユーティリティは SSR コードでのみ使用：

```moonbit
// 良い例: static_dom（SSR のみ）で使用
fn my_component() -> @static_dom.Node {
  div(class=@css.css("display", "flex"), [...])
}

// 避けるべき: Island クライアントコードでの使用
fn my_island() -> @luna.Node[Unit] {
  // これはクライアントバンドルに CSS コードを含めてしまう
  div(class=@css.css("display", "flex"), [...])

  // より良い: 事前計算されたクラス文字列を使用
  div(class="_z5et _3m33u", [...])
}
```

### Island での動的スタイリング

クライアントサイド Island での動的スタイリング：

```moonbit
// オプション 1: クラス名の切り替え
let class_name = if is_active.get() { "_active" } else { "_inactive" }
div(class=class_name, [...])

// オプション 2: CSS カスタムプロパティ
div(style="--color: " + color.get(), [...])

// オプション 3: 真に動的な値にはインラインスタイル
div(style="transform: translateX(" + x.get().to_string() + "px)", [...])
```

## API リファレンス

### ベーススタイル

| 関数 | 説明 | 例 |
|-----|------|-----|
| `css(prop, val)` | 単一宣言 | `css("display", "flex")` |
| `styles(pairs)` | 複数宣言 | `styles([("a", "b"), ...])` |
| `combine(classes)` | クラス名結合 | `combine([c1, c2])` |

### 疑似クラス

| 関数 | 説明 |
|-----|------|
| `on(pseudo, prop, val)` | 汎用疑似 |
| `hover(prop, val)` | :hover |
| `focus(prop, val)` | :focus |
| `active(prop, val)` | :active |

### メディアクエリ

| 関数 | 条件 |
|-----|------|
| `media(cond, prop, val)` | 汎用 |
| `at_sm(prop, val)` | min-width: 640px |
| `at_md(prop, val)` | min-width: 768px |
| `at_lg(prop, val)` | min-width: 1024px |
| `at_xl(prop, val)` | min-width: 1280px |
| `dark(prop, val)` | prefers-color-scheme: dark |

### 生成

| 関数 | 説明 |
|-----|------|
| `generate_css()` | ベーススタイルのみ |
| `generate_full_css()` | 全スタイル（ベース + 疑似 + メディア） |
| `reset_all()` | 全レジストリをクリア（テスト用） |

## 関連項目

- [Signals API](/ja/luna/api-js/signals/) - リアクティブ状態管理
- [Islands](/ja/luna/api-js/islands/) - Island アーキテクチャ
