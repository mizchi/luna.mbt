# Luna 改善提案

Moonlight SVG エディタの実装を通じて発見した Luna ライブラリの改善点をまとめる。

## 1. SVG 名前空間のサポート

### 問題

現在の `@element.create_element` は `document.createElement()` を使用しているため、SVG 要素を正しく作成できない。

```moonbit
// render.mbt:35-41
pub fn create_element(
  tag : String,
  attrs : Array[(String, AttrValue)],
  children : Array[DomNode],
) -> DomNode {
  let doc = @js_dom.document()
  let elem = doc.createElement(tag)  // ← これが問題
  ...
}
```

SVG 要素は `document.createElementNS('http://www.w3.org/2000/svg', tag)` で作成する必要がある。

### 現状のワークアラウンド

Moonlight では FFI で直接 `createElementNS` を呼び出している：

```moonbit
let svg_ns : String = "http://www.w3.org/2000/svg"

extern "js" fn create_svg_element_ffi(tag : String, ns : String) -> @js.Any =
  #| (tag, ns) => document.createElementNS(ns, tag)
```

### 提案 A: create_element_ns の追加

```moonbit
///|
/// Create an element with namespace (for SVG, MathML, etc.)
pub fn create_element_ns(
  ns : String,
  tag : String,
  attrs : Array[(String, AttrValue)],
  children : Array[DomNode],
) -> DomNode {
  let doc = @js_dom.document()
  let elem = create_element_ns_ffi(ns, tag)
  // ... 属性設定とchildrenの追加
  ...
}

extern "js" fn create_element_ns_ffi(ns : String, tag : String) -> @js_dom.Element =
  #| (ns, tag) => document.createElementNS(ns, tag)
```

### 提案 B: @element.svg モジュールの追加

よく使う SVG 要素のヘルパーを提供：

```moonbit
// @element.svg モジュール
let svg_ns : String = "http://www.w3.org/2000/svg"

pub fn svg(
  width~ : Int,
  height~ : Int,
  viewBox? : String,
  children : Array[DomNode],
) -> DomNode { ... }

pub fn rect(
  x~ : Double,
  y~ : Double,
  width~ : Double,
  height~ : Double,
  rx? : Double,
  ry? : Double,
  attrs? : Array[(String, AttrValue)],
) -> DomNode { ... }

pub fn circle(
  cx~ : Double,
  cy~ : Double,
  r~ : Double,
  attrs? : Array[(String, AttrValue)],
) -> DomNode { ... }

pub fn g(
  transform? : String,
  children : Array[DomNode],
) -> DomNode { ... }

// etc...
```

### 推奨

**提案 A** を優先。汎用的な `create_element_ns` があれば、SVG ヘルパーはユーザー側で実装可能。提案 B は別パッケージ（`@luna/svg` など）として提供するのが良い。

---

## 2. dom_node 関数のドキュメント強化

### 問題

`@element.dom_node()` 関数は存在するが、ドキュメントが不足している。外部で作成した DOM ノードを Luna のツリーに統合する際に重要。

### 現状

```moonbit
// node.mbt:103-105
pub fn[T : ToDomNode] dom_node(value : T) -> DomNode {
  ToDomNode::to_dom_node(value)
}
```

`ToDomNode` trait を実装している型（`@js_dom.Node`, `@js_dom.Element`, `String` など）を `DomNode` に変換できる。

### 提案

ドキュメントとサンプルを追加：

```moonbit
///|
/// Convert any ToDomNode value to DomNode
///
/// Supported types:
/// - @js_dom.Node -> Raw node
/// - @js_dom.Element -> Element node
/// - @js_dom.Text -> Text node
/// - String -> Text node (creates new text node)
/// - DomNode -> Identity (returns as-is)
///
/// Example - integrating external DOM:
/// ```moonbit
/// // Create SVG with external API
/// let svg = create_svg_element_ns("svg", svg_ns)
/// // Convert to DomNode for Luna tree
/// let node : @js_dom.Node = svg.cast()
/// div([dom_node(node)])
/// ```
pub fn[T : ToDomNode] dom_node(value : T) -> DomNode {
  ToDomNode::to_dom_node(value)
}
```

---

## 3. Effect の初回実行制御

### 問題

`@luna.effect` は作成時に即座に実行される。これは Ref の初期化順序によっては問題になる。

```moonbit
// 問題のあるコード
let svg_ref : Ref[@js.Any?] = { val: None }

let _ = @luna.effect(fn() {
  // effect は即座に実行されるが、svg_ref.val はまだ None
  match svg_ref.val {
    Some(svg) => redraw(svg)  // ここには来ない
    None => ()  // 初回は常にここ
  }
})

// ここで初期化される
svg_ref.val = Some(create_svg())
```

### 現状のワークアラウンド

初回実行をスキップするフラグを使用：

```moonbit
let is_first_run : Ref[Bool] = { val: true }

let _ = @luna.effect(fn() {
  let _ = state.elements.get()
  if is_first_run.val {
    is_first_run.val = false
    return
  }
  redraw()
})
```

### 提案 A: defer オプションの追加

```moonbit
///|
/// Create an effect that optionally defers first execution
pub fn effect(f : () -> Unit, defer? : Bool = false) -> EffectHandle {
  if defer {
    // 次のマイクロタスクまで実行を遅延
    queue_microtask(fn() { ... })
  } else {
    // 即時実行（現状の動作）
  }
  ...
}
```

### 提案 B: watch 関数の追加

Signal の変更のみを監視し、初回実行をスキップ：

```moonbit
///|
/// Watch signal changes (skip initial execution)
pub fn watch[T](
  sig : Signal[T],
  callback : (T, T) -> Unit,  // (new_value, old_value)
) -> WatchHandle {
  ...
}

// 使用例
let _ = @luna.watch(state.elements, fn(new_elements, _old) {
  redraw(new_elements)
})
```

### 推奨

**提案 B** の `watch` 関数。Solid.js の `createEffect` と `on` の組み合わせに相当し、より直感的な API になる。

---

## 4. 低優先度: Static/Raw ノードの違いの明確化

### 問題

`DomNode` には `Raw` と `Static` の 2 つのバリアントがあるが、違いがわかりにくい：

```moonbit
pub enum DomNode {
  El(DomElement)
  Txt(@js_dom.Text)
  Raw(@js_dom.Node)
  Static(@js_dom.Node)  // ← Raw との違いは？
}
```

### 現状

コメントによると `Static` は reconciliation/hydration でスキップされる。

### 提案

ドキュメントでユースケースを明確化：

```moonbit
pub enum DomNode {
  /// Element node (managed by Luna)
  El(DomElement)
  /// Text node (managed by Luna)
  Txt(@js_dom.Text)
  /// Raw node - included in reconciliation
  /// Use for external DOM that may change
  Raw(@js_dom.Node)
  /// Static node - skipped during reconciliation/hydration
  /// Use for pre-rendered content that never changes (e.g., SSR output, canvas)
  Static(@js_dom.Node)
}
```

---

## 5. Dataset 属性アクセスの簡略化

### 問題

`data-*` 属性へのアクセスが冗長で、nullish チェックが必要：

```moonbit
let target = e._get("target")
let dataset = target._get("dataset")
let data_id_raw = dataset._get("id")
let data_id : String? = if @js.is_nullish(data_id_raw) {
  None
} else {
  Some(data_id_raw.cast())
}
```

### 提案

ヘルパー関数の追加：

```moonbit
///|
/// Get dataset attribute from element, returns None if not present
pub fn get_data_attr(el : @js.Any, name : String) -> String? {
  let raw = el._get("dataset")._get(name)
  if @js.is_nullish(raw) { None } else { Some(raw.cast()) }
}

// 使用例
let data_id = get_data_attr(target, "id")
let data_handle = get_data_attr(target, "handle")
```

---

## 6. Signal のバッチ更新

### 問題

複数の Signal を更新する際、各更新で再描画が発生する可能性がある：

```moonbit
// 各行で effect が発火する可能性
state.elements.update(...)
state.selected_id.set(None)
state.resize_state.set(None)
```

### 現状

Luna には `@luna.batch` があるが、使い方が明確でない。

### 提案

ドキュメントでユースケースを明確化：

```moonbit
///|
/// Batch multiple signal updates to prevent intermediate re-renders
/// Effects are deferred until the batch completes
///
/// Example:
/// ```moonbit
/// @luna.batch(fn() {
///   state.elements.update(...)
///   state.selected_id.set(None)
///   state.context_menu.set(None)
/// })
/// // Effects run once here
/// ```
pub fn batch(f : () -> Unit) -> Unit { ... }
```

---

## 7. 複雑な状態の Signal 管理

### 問題

エディタのような複雑なアプリでは、多数の Signal を個別に管理することになる：

```moonbit
pub struct EditorState {
  elements : @luna.Signal[Array[Element]]
  selected_id : @luna.Signal[String?]
  drag_state : @luna.Signal[DragState?]
  resize_state : @luna.Signal[ResizeState?]
  context_menu : @luna.Signal[ContextMenu?]
  viewport : @luna.Signal[Viewport]
}
```

### 考察

- 各 Signal を個別に `get()` すると依存関係が登録される
- 一部だけ更新したい場合でも全体を意識する必要がある
- Zustand/Jotai のような selector パターンが欲しくなる

### 提案（将来）

Store パターンの強化：

```moonbit
// 現状の store を活用したセレクタ
let selected_element = @luna.memo(fn() {
  let id = state.selected_id.get()
  match id {
    Some(id) => state.elements.get().find(fn(el) { el.id == id })
    None => None
  }
})
```

---

## 8. 提案の優先度（更新）

| 優先度 | 提案 | 理由 |
|--------|------|------|
| 高 | 1A: `create_element_ns` | SVG/MathML の基本サポートに必須 |
| 高 | 2: `dom_node` ドキュメント | 既存機能の活用を促進 |
| 中 | 3B: `watch` 関数 | よくあるパターンの簡略化 |
| 中 | 5: `get_data_attr` ヘルパー | dataset アクセスの簡略化、よく使うパターン |
| 中 | 6: `batch` ドキュメント | 既存機能の活用を促進 |
| 低 | 4: DomNode ドキュメント | 高度なユースケース向け |
| 低 | 7: Store パターン | 将来的な改善、現状 memo で対応可能 |
| 低 | 1B: SVG ヘルパー | 別パッケージとして実装可能 |

---

## 参考: Moonlight での実装パターン

### SVG レンダリングの完全な例

```moonbit
// 1. FFI で SVG 要素を作成
let svg_ns : String = "http://www.w3.org/2000/svg"

extern "js" fn create_svg_element_ffi(tag : String, ns : String) -> @js.Any =
  #| (tag, ns) => document.createElementNS(ns, tag)

extern "js" fn set_svg_attr_ffi(el : @js.Any, name : String, value : String) =
  #| (el, name, value) => el.setAttribute(name, value)

extern "js" fn append_child_ffi(parent : @js.Any, child : @js.Any) =
  #| (parent, child) => parent.appendChild(child)

// 2. SVG 要素を作成
fn create_svg_element(tag : String, attrs : Array[(String, String)]) -> @js.Any {
  let el = create_svg_element_ffi(tag, svg_ns)
  for attr in attrs {
    set_svg_attr_ffi(el, attr.0, attr.1)
  }
  el
}

// 3. Luna ツリーに統合
pub fn svg_to_dom_node(svg : @js.Any) -> @element.DomNode {
  let node : @js_dom.Node = svg.cast()
  @element.dom_node(node)
}

// 4. 使用
fn editor_app() -> @element.DomNode {
  let svg = create_svg_element("svg", [("width", "800"), ("height", "600")])
  div([
    h1([text("Editor")]),
    svg_to_dom_node(svg),
  ])
}
```

### Effect の初回スキップパターン

```moonbit
fn setup_reactive_updates(state : EditorState, redraw : () -> Unit) -> Unit {
  let is_first_run : Ref[Bool] = { val: true }
  let _ = @luna.effect(fn() {
    // Signal を読み取って依存関係を登録
    let _ = state.elements.get()
    let _ = state.selected_id.get()
    // 初回はスキップ
    if is_first_run.val {
      is_first_run.val = false
      return
    }
    redraw()
  })
}
```
