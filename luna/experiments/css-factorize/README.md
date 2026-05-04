# CSS Factorization & Compression

CSSルールセットを集合として扱い、最小のユーティリティクラスを自動導出する実験。

## コンセプト

### 問題: BEM/コンポーネントCSSの冗長性

```css
/* 154 bytes - 同じプロパティが繰り返される */
.card__header { display: flex; align-items: center; padding: 1rem; }
.modal__footer { display: flex; align-items: center; padding: 1rem; }
.sidebar__nav { display: flex; align-items: center; }
```

### 解決: CSS因数分解

CSSを集合として扱い、共通部分を抽出:

```
R1 = {display:flex, align-items:center, padding:1rem}
R2 = {display:flex, align-items:center, padding:1rem}
R3 = {display:flex, align-items:center}

共通部分: {display:flex, align-items:center} → ._a
残り: {padding:1rem} → ._b
```

結果:
```css
/* 89 bytes - 42%削減 */
._a{display:flex;align-items:center}
._b{padding:1rem}
```

## ベンチマーク結果

| CSS | Before | After | 削減率 |
|-----|--------|-------|--------|
| BEM test (2KB) | 2,172 | 932 | **57%** |
| Astra main.css (43KB) | 43,164 | 20,480 | **53%** |
| Bootstrap 5.3 (232KB) | 232,911 | 108,382 | **53%** |
| Bulma 0.9 (207KB) | 207,302 | 43,124 | **79%** |
| Tailwind Preflight (8KB) | 7,695 | 6,556 | 15% |

**観察**: コンポーネントベースCSS (BEM, Bulma) は大幅削減。ユーティリティファースト (Tailwind) は既に最適化済み。

## アプローチ比較

### 1. 既存CSS因数分解 (factorize.js)

既存のCSSを後処理で最適化。

```bash
node factorize.js input.css
```

**課題**:
- HTMLのクラス参照も変換が必要
- 外部CSSとの衝突リスク
- 動的クラス名の追跡が困難

### 2. 圧縮前提の専用ユーティリティ (推奨)

最初から圧縮を前提としたCSSシステムを設計。

#### Tailwind風API (luna-utilities-concept.mbt)

```moonbit
h("div", [
  flex(),
  items_center(),
  p(S4),
], [...])
```

- ✅ 型安全
- ❌ CSS語彙を隠蔽 (新しい命名規則の学習が必要)

#### Direct CSS API (css-direct-api.mbt) ← 推奨

```moonbit
h("div", [
  css("display", "flex"),
  css("align-items", "center"),
  css("padding", "1rem"),
], [...])
```

- ✅ CSSプロパティ名をそのまま使用
- ✅ 既存のCSS知識がそのまま活きる
- ✅ 自動重複排除・圧縮
- ✅ `_`プレフィックスで外部CSS衝突回避

## Direct CSS API 詳細

### API一覧

| 関数 | 用途 | 例 |
|------|------|-----|
| `css(prop, val)` | 基本スタイル | `css("display", "flex")` |
| `styles(pairs)` | 複数スタイル | `styles([("display", "flex"), ...])` |
| `on(pseudo, prop, val)` | 擬似セレクタ | `on(":hover", "color", "red")` |
| `hover(prop, val)` | :hover | `hover("background", "#eee")` |
| `focus(prop, val)` | :focus | `focus("outline", "2px solid blue")` |
| `active(prop, val)` | :active | `active("transform", "scale(0.98)")` |
| `media(cond, prop, val)` | メディアクエリ | `media("min-width: 768px", "padding", "2rem")` |
| `at_sm/md/lg/xl(prop, val)` | ブレークポイント | `at_md("font-size", "1.25rem")` |
| `dark(prop, val)` | ダークモード | `dark("background", "#1a1a1a")` |

### 基本使用

```moonbit
fn card() -> Node {
  h("div", [
    css("display", "flex"),
    css("align-items", "center"),
    css("padding", "1rem"),
    css("border-radius", "0.5rem"),
  ], [
    text("Card content")
  ])
}
```

### 出力

HTML:
```html
<div class="_a _b _c _d">Card content</div>
```

CSS (使用分のみ):
```css
._a{display:flex}._b{align-items:center}._c{padding:1rem}._d{border-radius:0.5rem}
```

### 一括指定

```moonbit
fn button() -> Node {
  h("button", [
    styles([
      ("display", "inline-flex"),
      ("padding", "0.5rem 1rem"),
      ("cursor", "pointer"),
    ]),
  ], [...])
}
```

### 共通スタイルの再利用

```moonbit
// 共通パターンを関数化
fn flex_center() -> Array[(String, String)] {
  [("display", "flex"), ("align-items", "center"), ("justify-content", "center")]
}

// 複数箇所で使用 → 同じクラスが再利用される
fn modal_overlay() -> Node {
  h("div", [styles(flex_center())], [...])
}

fn dialog() -> Node {
  h("div", [styles(flex_center())], [...])  // 同じ ._a ._b ._c が出力
}
```

## 懸念点と対策

### 1. 外部CSSとの衝突

**問題**: 生成クラス名が外部ライブラリと衝突する可能性

**対策**: `_`プレフィックス付与
```css
._a{display:flex}  /* 衝突しにくい */
```

### 2. 動的スタイル (Signal連動)

**問題**: Signalで値が変わるスタイルは静的最適化できない

```moonbit
// 静的 → 最適化対象
css("color", "red")

// 動的 → 最適化スコープ外
css("color", color_signal.get())  // ← 値が実行時に決まる
```

**対策**: 動的スタイルは別扱い

```moonbit
// 静的スタイル → クラス化
css("display", "flex")  // → class="_a"

// 動的スタイル → inline style
dynamic_css("color", color_signal)  // → style="color: ${value}"
```

または、動的部分のみCSS変数化:

```moonbit
// 静的部分
css("color", "var(--dynamic-color)")  // → class="_a" (._a{color:var(--dynamic-color)})

// 動的部分はCSS変数で注入
style("--dynamic-color", color_signal.get())
```

### 3. 疑似クラス・メディアクエリ

**設計方針**: CSSセレクタ名をそのまま露出

#### 汎用API: `on()`

```moonbit
// 擬似クラス
on(":hover", "background", "#2563eb")
on(":focus", "outline", "2px solid blue")
on(":active", "transform", "scale(0.98)")

// 擬似要素
on("::before", "content", "\"→\"")
on("::after", "content", "\"\"")
```

出力:
```css
._h1:hover{background:#2563eb}
._f1:focus{outline:2px solid blue}
._ac1:active{transform:scale(0.98)}
```

#### 便利ラッパー

```moonbit
// よく使う擬似クラス用
hover("background", "#2563eb")   // on(":hover", ...) のショートカット
focus("outline", "2px solid blue")
active("transform", "scale(0.98)")
```

#### メディアクエリ: `media()`

```moonbit
// 汎用
media("min-width: 768px", "padding", "2rem")
media("prefers-color-scheme: dark", "background", "#1a1a1a")

// ブレークポイント便利ラッパー
at_sm("padding", "1rem")    // 640px
at_md("padding", "1.5rem")  // 768px
at_lg("padding", "2rem")    // 1024px
at_xl("padding", "2.5rem")  // 1280px

// ダークモード
dark("background", "#1a1a1a")
dark("color", "white")
```

出力:
```css
@media(min-width:768px){._m0{padding:2rem}}
@media(prefers-color-scheme:dark){._m1{background:#1a1a1a}}
```

#### 使用例: インタラクティブボタン

```moonbit
fn button() -> @luna.Node {
  @luna.h("button", [
    // ベーススタイル
    css("display", "inline-flex"),
    css("padding", "0.5rem 1rem"),
    css("background", "#3b82f6"),
    css("color", "white"),
    css("border-radius", "0.375rem"),

    // インタラクション
    hover("background", "#2563eb"),
    focus("outline", "2px solid #93c5fd"),
    active("transform", "scale(0.98)"),

    // レスポンシブ
    at_md("padding", "0.75rem 1.5rem"),
    at_lg("font-size", "1.125rem"),
  ], [...])
}
```

#### 使用例: ダークモード対応カード

```moonbit
fn card() -> @luna.Node {
  @luna.h("div", [
    css("background", "white"),
    css("color", "#1a1a1a"),
    dark("background", "#1a1a1a"),
    dark("color", "white"),
  ], [...])
}
```

### 4. Shadow DOM境界

**問題**: Shadow DOM内では外部CSSが適用されない

```
Document
├── <style>._a{display:flex}</style>    ← グローバルCSS
├── <div class="_a">✓</div>              ← 適用される
└── <wc-counter>
    └── #shadow-root
        └── <div class="_a">✗</div>      ← 適用されない
```

**対策案**:

#### 案1: コンポーネント単位のスタイル追跡

各コンポーネントで使用するスタイル宣言を追跡し、Shadow Root生成時に注入:

```moonbit
// ビルド時に収集
fn counter_styles() -> String {
  // このコンポーネントで使用される宣言のみ
  "._a{display:flex}._b{align-items:center}"
}

fn counter() -> @luna.Node {
  wc_island("wc-counter", "/counter.js", [
    // 子要素
  ], styles=counter_styles())
}
```

#### 案2: Adoptable Stylesheets

ブラウザのCSSStyleSheet APIを使用して、複数のShadow Rootでスタイルシートを共有:

```javascript
// グローバルに1つのスタイルシートを作成
const globalSheet = new CSSStyleSheet();
globalSheet.replaceSync("._a{display:flex}._b{align-items:center}...");

// 各Shadow Rootで採用
shadowRoot.adoptedStyleSheets = [globalSheet];
```

**SSRとの整合性問題**:

```
SSR出力:
<template shadowrootmode="open">
  <style>._a{display:flex}</style>  ← Declarative Shadow DOM用
  <div class="_a">...</div>
</template>

Hydration後:
#shadow-root
  <style>._a{...}</style>           ← SSRのスタイル (残存)
  adoptedStyleSheets: [sheet]       ← 追加 → 二重適用！
```

**対策: Hydration時に置換**

```javascript
// Hydration時にSSRの<style>を削除してAdoptable Stylesheetsに切り替え
function hydrateWithStyles(shadowRoot) {
  // 1. SSRで注入されたユーティリティスタイルを削除
  shadowRoot.querySelectorAll('style[data-utility]').forEach(s => s.remove());

  // 2. グローバルシートを採用
  shadowRoot.adoptedStyleSheets = [window.__LUNA_STYLES__];
}
```

MoonBit側:
```moonbit
// 初期化時にグローバルシートを登録
fn init_global_styles() -> Unit {
  let css = generate_css()
  register_adoptable_sheet(css)
}

// Hydration時: SSRスタイル削除 + Adoptable採用
fn hydrate_wc(element : @js_dom.Element) -> Unit {
  let shadow = get_shadow_root(element)
  remove_utility_styles(shadow)  // data-utility属性のstyleを削除
  adopt_global_styles(shadow)
}
```

**SSR時のマーキング**:
```html
<style data-utility>._a{display:flex}...</style>  <!-- 削除対象 -->
<style>:host{display:block;}</style>              <!-- コンポーネント固有、保持 -->
```

利点:
- メモリ効率（シート共有）
- スタイル更新が全Shadow Rootに反映
- パースコスト削減
- SSR時はFOUC防止、Hydration後は効率化

#### 案3: SSRスタイルをそのまま使用 (最もシンプル)

Adoptable Stylesheetsを使わず、SSRで注入した`<style>`をそのまま維持:

```
SSR:
<template shadowrootmode="open">
  <style>._a{display:flex}._b{...}</style>
  <div class="_a _b">...</div>
</template>

Hydration後:
#shadow-root
  <style>._a{display:flex}._b{...}</style>  ← そのまま
  <div class="_a _b">...</div>
```

現在のLunaの`extract_style_elements()`がこれを実現。

利点:
- 実装がシンプル
- SSR/Hydrationで一貫性

欠点:
- 同じCSSが各Shadow Rootで重複
- メモリ効率が悪い（多数のコンポーネントで顕著）

**判断基準**:
- コンポーネント数が少ない → 案3（シンプル）
- コンポーネント数が多い → 案2（Adoptable Stylesheets）

#### 実装時の選択オプション

```moonbit
/// スタイル注入モード
pub enum StyleMode {
  /// SSRで注入した<style>をそのまま使用（デフォルト）
  Inline
  /// Adoptable Stylesheetsで共有（Hydration時に切り替え）
  Adoptable
}

/// アプリケーション設定
pub struct StyleConfig {
  mode : StyleMode
  /// Adoptableモード時: グローバルシートを事前登録
  preload_sheet : Bool
}

let default_config : StyleConfig = {
  mode: Inline,
  preload_sheet: false,
}
```

**Inlineモード** (デフォルト):
```moonbit
// SSR: 各Shadow Rootに<style>を埋め込み
fn render_wc_styles(island : VWcIsland) -> String {
  "<style>" + island.utility_css + "</style>"
}

// Hydration: 何もしない（SSRのスタイルをそのまま使用）
fn hydrate_styles(shadow : @js.Any, config : StyleConfig) -> Unit {
  match config.mode {
    Inline => ()  // no-op
    Adoptable => ...
  }
}
```

**Adoptableモード**:
```moonbit
// SSR: マーカー付きで埋め込み
fn render_wc_styles(island : VWcIsland) -> String {
  "<style data-luna-utility>" + island.utility_css + "</style>"
}

// Hydration: 置換
fn hydrate_styles(shadow : @js.Any, config : StyleConfig) -> Unit {
  match config.mode {
    Inline => ()
    Adoptable => {
      remove_utility_styles(shadow)
      adopt_global_styles(shadow)
    }
  }
}
```

**使用例**:
```moonbit
// main.mbt - アプリ初期化時に選択
fn main() {
  // 開発時: シンプルなInlineモード
  @css.init(mode=Inline)

  // 本番/大規模: Adoptableモード
  // @css.init(mode=Adoptable, preload_sheet=true)
}
```

**ビルド時フラグ**:
```bash
# 開発
moon build --define CSS_MODE=inline

# 本番
moon build --define CSS_MODE=adoptable
```

#### 案4: ハイドレーション単位でのスタイル分割

ビルド時にハイドレーション境界を検出し、スタイルを分割:

```
build output:
├── global.css        # Document用
├── counter.css       # wc-counter Shadow Root用
└── modal.css         # wc-modal Shadow Root用
```

### 5. デバッグの困難さ

**問題**: `._a ._b ._c` だと何のスタイルか分からない

**対策**: 開発モードで元の宣言をコメント出力

```css
/* dev mode */
._a{display:flex}/* display:flex */
._b{align-items:center}/* align-items:center */

/* prod mode */
._a{display:flex}._b{align-items:center}
```

## 実装ロードマップ

### Phase 1: プロトタイプ (現在)
- [x] CSS因数分解アルゴリズム (factorize.js)
- [x] ベンチマーク検証
- [x] API設計案

### Phase 2: Luna統合 ✅
- [x] `css()` / `styles()` 関数実装
- [x] StyleRegistry (使用スタイル追跡)
- [x] ビルド時CSS生成 (`generate_full_css()`)

### Phase 3: 静的CSS抽出 ✅
- [x] 静的解析による全CSS宣言の抽出 (`src/luna/css/extract.js`)
- [x] ビルドパイプライン統合 (`just extract-css`)
- [x] JSON形式出力（マッピング情報付き）

### Phase 4: 高度な機能
- [x] 疑似クラス対応 (`on()`, `hover()`, `focus()`, `active()`)
- [x] メディアクエリ対応 (`media()`, `at_sm()`, `at_md()`, `at_lg()`, `at_xl()`)
- [x] ダークモード対応 (`dark()`)
- [ ] CSS変数連携
- [ ] 動的スタイルの自動判別
- [ ] Shadow DOM対応 (Adoptable Stylesheets)

### Phase 5: 最適化
- [ ] 宣言の出現順最適化 (gzip効率)
- [ ] クリティカルCSS抽出
- [ ] 未使用スタイルの警告

## ファイル構成

```
experiments/css-factorize/
├── README.md                    # このファイル
├── factorize.js                 # CSS因数分解アルゴリズム
├── runtime.js                   # ランタイム展開 (実験的)
├── test.css                     # テスト用BEM CSS
├── luna-utilities-concept.mbt   # Tailwind風API案
├── css-direct-api.mbt           # Direct CSS API案 (推奨)
└── luna-integration.md          # Luna統合戦略
```

## 使い方

```bash
# 既存CSSの因数分解テスト
node factorize.js test.css

# 詳細表示
node factorize.js input.css -v

# クラスマッピング出力
node factorize.js input.css --mapping

# ランタイム形式出力
node factorize.js input.css --runtime
```

## 設計決定まとめ

### 全体アーキテクチャ

```
┌─────────────────────────────────────────────────────────────┐
│  MoonBit Component                                          │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ css("display", "flex")                              │   │
│  │ hover("background", "#2563eb")                      │   │
│  │ at_md("padding", "2rem")                            │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  StyleRegistry (ビルド時)                                    │
│  - 宣言 → クラス名マッピング                                  │
│  - 重複排除                                                  │
│  - 使用スタイル追跡                                          │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  SSR Output                                                 │
│  ┌─────────────────┐  ┌─────────────────────────────────┐  │
│  │ Document        │  │ Shadow Root (WC Island)         │  │
│  │ <style>         │  │ <style data-luna-utility>       │  │
│  │ ._a{...}        │  │ ._a{...}                        │  │
│  │ </style>        │  │ </style>                        │  │
│  └─────────────────┘  └─────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  Hydration (StyleMode による分岐)                            │
│  ┌────────────────────┐  ┌────────────────────────────┐    │
│  │ Inline (default)   │  │ Adoptable                  │    │
│  │ SSRスタイル維持     │  │ SSR削除 → 共有シート採用    │    │
│  └────────────────────┘  └────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

### 設計決定一覧

| 項目 | 決定 | 理由 |
|------|------|------|
| **API形式** | Direct CSS (`css("prop", "val")`) | CSS知識をそのまま活用、学習コスト低 |
| **クラス名** | `_` プレフィックス (`._a`, `._b`) | 外部CSSとの衝突回避 |
| **擬似セレクタ** | `on(":hover", ...)` + 便利ラッパー | CSS構文を露出しつつ利便性確保 |
| **メディアクエリ** | `media("condition", ...)` + `at_md()` 等 | 汎用性と利便性のバランス |
| **動的スタイル** | inline style または CSS変数 | 静的最適化スコープから分離 |
| **Shadow DOM** | `StyleMode` で選択可能 | 規模に応じた最適化 |
| **SSR整合性** | `data-luna-utility` マーカー | Hydration時の安全な置換 |

### コア型定義

```moonbit
/// スタイル宣言レジストリ
struct StyleRegistry {
  decl_to_class : HashMap[String, String]  // "display:flex" → "_a"
  declarations : Array[String]              // 出現順
  mut counter : Int
}

/// 擬似セレクタレジストリ
struct PseudoRegistry {
  pseudo_to_class : HashMap[String, String]  // ":hover:bg:#fff" → "_h1"
  mut hover_counter : Int
  mut focus_counter : Int
  mut active_counter : Int
}

/// メディアクエリレジストリ
struct MediaRegistry {
  media_to_class : HashMap[String, String]  // "@media(...):..." → "_m0"
  mut counter : Int
}

/// スタイルモード（Shadow DOM対応）
pub enum StyleMode {
  Inline      // SSRスタイル維持（シンプル）
  Adoptable   // 共有シート（効率的）
}

/// 設定
pub struct StyleConfig {
  mode : StyleMode
  preload_sheet : Bool
}
```

### API一覧（完全版）

```moonbit
// ─── 基本スタイル ───
css(property: String, value: String) -> Attr
styles(pairs: Array[(String, String)]) -> Attr

// ─── 擬似セレクタ ───
on(pseudo: String, property: String, value: String) -> Attr  // 汎用
hover(property: String, value: String) -> Attr
focus(property: String, value: String) -> Attr
active(property: String, value: String) -> Attr

// ─── メディアクエリ ───
media(condition: String, property: String, value: String) -> Attr  // 汎用
at_sm(property: String, value: String) -> Attr  // min-width: 640px
at_md(property: String, value: String) -> Attr  // min-width: 768px
at_lg(property: String, value: String) -> Attr  // min-width: 1024px
at_xl(property: String, value: String) -> Attr  // min-width: 1280px
dark(property: String, value: String) -> Attr   // prefers-color-scheme: dark

// ─── 動的スタイル ───
dynamic_css(property: String, signal: Signal[String]) -> Attr  // inline style
css_var(name: String, signal: Signal[String]) -> Attr          // CSS変数

// ─── CSS生成 ───
generate_css() -> String           // 基本スタイルのみ
generate_full_css() -> String      // 擬似 + メディア含む

// ─── Shadow DOM ───
init_styles(config: StyleConfig) -> Unit
hydrate_styles(shadow: Any, config: StyleConfig) -> Unit
```

### 使用例（完全版）

```moonbit
fn interactive_card() -> @luna.Node {
  @luna.h("div", [
    // ベーススタイル
    styles([
      ("display", "flex"),
      ("flex-direction", "column"),
      ("padding", "1.5rem"),
      ("border-radius", "0.5rem"),
      ("background", "white"),
      ("box-shadow", "0 1px 3px rgba(0,0,0,0.1)"),
    ]),

    // ダークモード
    dark("background", "#1e1e1e"),
    dark("color", "#e5e5e5"),

    // ホバーエフェクト
    hover("box-shadow", "0 4px 12px rgba(0,0,0,0.15)"),
    hover("transform", "translateY(-2px)"),

    // レスポンシブ
    at_md("padding", "2rem"),
    at_lg("flex-direction", "row"),
  ], [
    @luna.text("Card content")
  ])
}
```

出力CSS:
```css
/* 基本 */
._a{display:flex}._b{flex-direction:column}._c{padding:1.5rem}
._d{border-radius:0.5rem}._e{background:white}
._f{box-shadow:0 1px 3px rgba(0,0,0,0.1)}

/* ダークモード */
@media(prefers-color-scheme:dark){._m0{background:#1e1e1e}._m1{color:#e5e5e5}}

/* ホバー */
._h1:hover{box-shadow:0 4px 12px rgba(0,0,0,0.15)}
._h2:hover{transform:translateY(-2px)}

/* レスポンシブ */
@media(min-width:768px){._m2{padding:2rem}}
@media(min-width:1024px){._m3{flex-direction:row}}
```

### 実装状況

#### ✅ Phase 2: Luna統合 (完了)

実装済み: `src/luna/css/`

```moonbit
// 基本API
css("display", "flex")           // → "_a"
styles([("display", "flex")])    // → "_a"

// 擬似クラス
hover("background", "#2563eb")   // → "_h0"
focus("outline", "2px solid")    // → "_f0"

// メディアクエリ
at_md("padding", "2rem")         // → "_m0"
dark("background", "#1a1a1a")    // → "_m1"

// CSS生成
generate_full_css()              // SSR時に呼び出し
```

static_dom/element からも利用可能:
```moonbit
div(class=ucss("display", "flex"), [...])
```

詳細: [src/luna/css/README.md](../../src/luna/css/README.md)

#### ✅ Phase 3: 静的CSS抽出 (完了)

ビルド時に全`.mbt`ファイルから静的解析でCSS宣言を抽出:

```bash
# 基本使用
just extract-css src

# ファイル出力
just extract-css src output=dist/styles.css

# JSON形式（マッピング情報付き）
just extract-css-json src
```

抽出対象パターン:
- `css("property", "value")`
- `styles([("property", "value"), ...])`
- `hover/focus/active("property", "value")`
- `on(":pseudo", "property", "value")`
- `media("condition", "property", "value")`
- `at_sm/md/lg/xl("property", "value")`
- `dark("property", "value")`
- `u*` プレフィックス版（static_dom re-exports）

実装: `src/luna/css/extract.js`

#### 🔲 Phase 4: 高度な機能
- [ ] CSS変数連携
- [ ] 動的スタイルの自動判別
- [ ] Shadow DOM対応（StyleMode実装）

#### 🔲 Phase 5: 最適化
- [ ] gzip効率のための宣言順最適化
- [ ] クリティカルCSS抽出
- [ ] Tree-shaking（未使用スタイル警告）
