# Luna SVG 対応の提案

## 概要

Luna で SVG 要素を扱うために `createElementNS` のサポートが必要。
これにより、SVG 要素を Luna の VNode として管理でき、Signal ベースの差分更新が可能になる。

## 現状の問題

### 1. SVG 要素が Luna の仮想 DOM 外

```moonbit
// Luna の現在の実装（element パッケージ）
let elem = doc.createElement(tag)  // HTML 用の API

// SVG は namespace が必要
let elem = doc.createElementNS("http://www.w3.org/2000/svg", tag)
```

Luna の `create_element` は `document.createElement()` を使用するため、SVG 要素を正しく作成できない。

### 2. Moonlight での回避策

FFI で直接 SVG 要素を作成し、Luna のツリー外で管理：

```moonbit
// ffi.mbt
extern "js" fn create_svg_element_ffi(tag : String, ns : String) -> @js.Any =
  #| (tag, ns) => document.createElementNS(ns, tag)

// render.mbt
fn create_svg_element(tag : String, attrs : Array[(String, String)]) -> @js.Any {
  let el = create_svg_element_ffi(tag, svg_ns)
  for attr in attrs {
    set_svg_attr_ffi(el, attr.0, attr.1)
  }
  el
}
```

### 3. 結果：差分更新ができない

Luna の Signal/For による差分更新が使えず、毎回全要素を再作成：

```moonbit
fn redraw_svg_content(...) {
  clear_children_ffi(svg)  // 全子要素を削除

  for el in elements {
    let child = render_element(el)  // 毎回新規作成
    append_child_ffi(svg, child)
  }
}
```

**問題点：**
- ドラッグ中も全要素が再描画される
- 要素数が増えるとパフォーマンスが劣化
- Signal の変更追跡の恩恵を受けられない

## 提案する変更

### Luna 側の変更

#### 1. `create_element_ns` 関数の追加

```moonbit
// @element パッケージに追加
pub fn create_element_ns(
  ns : String,
  tag : String,
  attrs : Array[(String, AttrValue)],
  children : Array[DomNode],
) -> DomNode {
  let doc = @js_dom.document()
  let elem = create_element_ns_ffi(ns, tag)
  // 属性設定
  for attr in attrs {
    match attr.1 {
      AttrString(s) => elem.setAttribute(attr.0, s)
      AttrDynamic(f) => // 動的属性の処理
      // ...
    }
  }
  // 子要素追加
  for child in children {
    append_child(elem, child)
  }
  DomNode::El(DomElement::from_element(elem))
}

extern "js" fn create_element_ns_ffi(ns : String, tag : String) -> @js_dom.Element =
  #| (ns, tag) => document.createElementNS(ns, tag)
```

#### 2. SVG ヘルパーモジュール（オプション）

```moonbit
// @element.svg モジュール
let svg_ns : String = "http://www.w3.org/2000/svg"

pub fn svg(
  width~ : Int,
  height~ : Int,
  viewBox? : String,
  children : Array[DomNode],
) -> DomNode {
  create_element_ns(svg_ns, "svg", [...], children)
}

pub fn rect(
  x~ : Double,
  y~ : Double,
  width~ : Double,
  height~ : Double,
  attrs? : Array[(String, AttrValue)],
) -> DomNode { ... }

pub fn circle(cx~ : Double, cy~ : Double, r~ : Double) -> DomNode { ... }
pub fn line(x1~ : Double, y1~ : Double, x2~ : Double, y2~ : Double) -> DomNode { ... }
pub fn g(children : Array[DomNode]) -> DomNode { ... }
pub fn text_(x~ : Double, y~ : Double, content : String) -> DomNode { ... }
```

### 期待される効果

#### Before（現状）

```
Signal更新 → effect発火 → clear_children → 全要素再作成 → 全DOM更新
```

#### After（提案後）

```
Signal更新 → For が差分計算 → 変更要素のみ DOM 更新
```

### Moonlight 側の変更（Luna 対応後）

```moonbit
// 現在の実装
fn editor_app() -> @element.DomNode {
  let svg = create_svg_ffi(...)  // FFI で作成
  svg_to_dom_node(svg)           // Luna に統合
}

fn redraw_svg_content() {
  clear_children_ffi(svg)        // 全削除
  for el in elements {
    append_child_ffi(...)        // 全再作成
  }
}

// 提案後の実装
fn editor_app() -> @element.DomNode {
  @element.svg.svg(
    width=canvas_width,
    height=canvas_height,
    [
      // グリッド
      show(fn() { state.grid_enabled.get() }, fn() {
        render_grid_lines()
      }),

      // 要素リスト - For による差分更新
      @luna.for(
        fn() { state.elements.get() },
        key=fn(el) { el.id },  // キーベース差分
        fn(el) {
          @element.svg.rect(
            x=el.x,
            y=el.y,
            width=el.width,
            height=el.height,
          )
        },
      ),

      // 選択ハンドル
      show(fn() { state.selected_ids.get().length() > 0 }, fn() {
        render_handles()
      }),
    ],
  )
}
```

## 実装の優先度

| 項目 | 優先度 | 理由 |
|------|--------|------|
| `create_element_ns` 関数 | **高** | SVG/MathML の基本サポートに必須 |
| For の namespace 対応 | **高** | 差分更新に必須 |
| SVG ヘルパーモジュール | 中 | ユーザー側で実装可能 |

## 代替案：Luna 変更なしでの最適化

Luna の変更を待たずに Moonlight 側で最適化する場合：

### ドラッグ中の軽量更新

```moonbit
// ドラッグ中は setAttribute で座標のみ更新
fn update_element_position_fast(el_id : String, x : Double, y : Double) {
  let dom = query_selector_ffi("[data-id='\{el_id}']")
  match get_element_type(dom) {
    "rect" => {
      set_svg_attr_ffi(dom, "x", x.to_string())
      set_svg_attr_ffi(dom, "y", y.to_string())
    }
    "circle" => {
      set_svg_attr_ffi(dom, "cx", x.to_string())
      set_svg_attr_ffi(dom, "cy", y.to_string())
    }
    "line" => {
      // Line は始点と終点を更新
    }
    _ => ()
  }
}

// ドラッグ終了時のみ完全再描画
fn on_drag_end() {
  redraw_svg_content()  // 全体を再描画してUIと同期
}
```

**メリット:**
- Luna の変更不要
- ドラッグ中のパフォーマンス向上

**デメリット:**
- 二重管理（Signal + DOM 直接操作）
- コードの複雑化
- Luna の思想に反する

## 結論

`create_element_ns` のサポートは：

1. **SVG アプリケーションの基盤** - 正しい SVG 要素の作成
2. **パフォーマンスの鍵** - Signal ベースの差分更新が可能に
3. **MathML など他の namespace にも対応** - 汎用的な解決策

Luna の Web UI フレームワークとしての価値を高める重要な機能であり、優先度高で対応を推奨。
