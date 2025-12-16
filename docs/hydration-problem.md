# Hydration Problem: DomNode vs VNode

## 概要

`hydrate_auto_dom` は「hydrate」という名前だが、実際には CSR（Client-Side Rendering）を行っている。これは設計上の制約による。

## 問題の詳細

### 2つの Hydration API

1. **`hydrate_auto`** - VNode (`@luna.Node[@js.Any]`) を受け取る
   - SSR された DOM を再利用できる（真の hydration）
   - 既存 DOM にイベントハンドラをアタッチ
   - `@client.hydrate(shadow_root, node)` を使用

2. **`hydrate_auto_dom`** - DomNode (`@element.DomNode`) を受け取る
   - SSR された DOM を再利用できない（CSR になる）
   - 新しい DOM を生成して置換
   - DocumentFragment で atomic 置換（フラッシュ最小化）

### なぜ DomNode では真の hydration ができないか

```
SSR HTML (静的)          VNode (宣言的)           DomNode (命令的)
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│ <div>       │         │ Element {   │         │ 既に作成された│
│   <button>  │   ←→    │   tag,      │   ✗     │ DOM ノード   │
│     +1      │         │   attrs,    │         │ (Signal 付き) │
│   </button> │         │   children  │         │              │
│ </div>      │         │ }           │         │              │
└─────────────┘         └─────────────┘         └─────────────┘
       ↑                       ↑                       │
       │                       │                       │
       └───── hydrate ─────────┘                       │
              (イベントハンドラ                         │
               をアタッチ)                             │
                                                       ↓
                                              CSR (置換するしかない)
```

- **VNode**: 宣言的な構造。SSR HTML と照合してイベントハンドラだけをアタッチできる
- **DomNode**: 既に `document.createElement` で作成された DOM。Signal でリアクティブにバインド済み

DomNode は既に実体を持つ DOM なので、SSR された別の DOM を「再利用」することができない。

## 現在の動作

### WC (Web Components) モード

```moonbit
// src/platform/dom/wc_island.mbt

pub fn hydrate_auto_dom(element, node) {
  if has_shadow_root(element) {
    // 1. 新しい DOM を先に準備
    let new_content = node.to_jsdom()

    // 2. DocumentFragment で atomic 置換
    let fragment = doc.createDocumentFragment()

    // 3. SSR スタイルを保持
    let styles = extract_style_elements(shadow_root)
    for style in styles {
      fragment.appendChild(style)
    }

    // 4. 新しいコンテンツを追加
    fragment.appendChild(new_content)

    // 5. クリアして置換（1回の reflow で済む）
    shadow_root.setTextContent("")
    shadow_root.appendChild(fragment)
  }
}
```

### 影響

- SSR された HTML は破棄される（初期描画の利点が一部失われる）
- CSS は保持されるので FOUC (Flash of Unstyled Content) は防げる
- DocumentFragment 使用でフラッシュは最小化

## 解決策の候補

### 1. VNode ベースに統一（推奨）

`@element` DSL を使わず、`@luna.Node` を返すようにする。

```moonbit
// Before: DomNode を返す
pub fn counter(props : CounterProps) -> @element.DomNode {
  div(class="counter", [...])
}

// After: VNode を返す
pub fn counter(props : CounterProps) -> @luna.Node[@js.Any] {
  @luna.div([("class", @luna.static("counter"))], [...])
}
```

**メリット**: 真の hydration が可能
**デメリット**: DSL の書き味が変わる、既存コードの移行が必要

### 2. DomNode から VNode への変換レイヤー

DomNode の構造を解析して VNode を再構築する。

**メリット**: 既存 API を維持
**デメリット**: 実装が複雑、Signal の再構築が必要

### 3. 現状維持（CSR を受け入れる）

- 初期描画は SSR で速い
- hydration 時に一瞬フラッシュするが許容
- 小さいコンポーネントなら影響は軽微

## 推奨事項

1. **小さい Island**: 現状維持で問題ない。CSR のオーバーヘッドは軽微。

2. **大きい Island**: VNode ベースの API (`hydrate_auto`) を使用を検討。

3. **パフォーマンスクリティカル**: VNode ベースに移行するか、Island を細分化。

## 関連ファイル

- `src/platform/dom/wc_island.mbt` - `hydrate_auto_dom` の実装
- `src/platform/dom/client/hydrate.mbt` - VNode ベースの hydration
- `examples/sol_app/app/__gen__/client/exports.mbt` - 生成される hydrate wrapper
