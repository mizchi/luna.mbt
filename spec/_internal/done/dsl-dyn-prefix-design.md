# DSL Dynamic Attribute Design: dyn_ prefix

## 背景

Luna UI の要素 DSL において、静的属性と動的属性の記述方法に一貫性がなかった。

### 問題点（Before）

```moonbit
// 静的属性: 簡潔に書ける
input(class="toggle", type_="checkbox", ...)

// 動的属性: dyn_attrs に分離、タプル配列形式で冗長
dyn_attrs=[
  ("checked", attr_dynamic(() => get_todo().completed.to_string())),
  ("change", Handler(_ => toggle_todo(get_todo().id))),
]
```

課題:
1. 静的と動的の構文が分離している
2. 動的属性の記述が冗長（タプル形式、`attr_dynamic` ラップ）
3. どの属性が動的かがコードを読むまでわからない

## 設計決定

### 1. `dyn_` prefix による動的属性

各属性に対して `dyn_` prefix 版のパラメータを追加する。

```moonbit
pub fn input(
  // 静的
  type_? : String,
  class? : String,
  value? : String,
  checked? : Bool,
  disabled? : Bool,

  // 動的 (dyn_ prefix)
  dyn_class? : () -> String,
  dyn_value? : () -> String,
  dyn_checked? : () -> Bool,
  dyn_disabled? : () -> Bool,
  dyn_style? : () -> String,

  // イベント・その他
  on? : HandlerMap,
  ref_? : ElementRef,

  // エスケープハッチ（未定義属性用）
  attrs? : Array[(String, Attr)],
  dyn_attrs? : Array[(String, AttrValue)],
) -> DomNode
```

### 2. After: 新しい DSL

```moonbit
input(
  class="toggle",
  type_="checkbox",
  dyn_checked=fn() { get_todo().completed },
  on=events().change(_ => toggle_todo(id)),
)
```

### 3. なぜ prefix か

- **視認性**: 行頭で静的/動的が一目瞭然
- **IDE補完**: `dyn_` と打てば動的属性が全てリストアップされる
- **グルーピング**: コード上で動的属性がまとまって見える
- **静的解析**: どの属性がリアクティブか即座に判断可能

### 4. なぜ `() -> T` を受け取るか（Signal ではなく）

ベンチマーク結果:

| ケース | 時間 (1000回) |
|--------|---------------|
| 直接関数呼び出し | **0.36 µs** |
| Signal.get() | 1.18 µs |
| api: `() -> T` パラメータ | **0.29 µs** |
| api: `Signal[T]` パラメータ | 0.36 µs |

- `Signal.get()` は subscriber tracking のオーバーヘッドで約3倍遅い
- `() -> T` を受け取る方が柔軟（Signal でも memo でも computed でも受けられる）
- Signal ユーザーは `fn() { sig.get() }` とラップするか、ヘルパー `dyn(signal)` を使用

## ヘルパー関数

```moonbit
/// Signal を () -> T に変換
pub fn dyn[T](signal : Signal[T]) -> () -> T {
  fn() { signal.get() }
}

/// Signal を () -> String に変換（Show 制約）
pub fn dyn_show[T : Show](signal : Signal[T]) -> () -> String {
  fn() { signal.get().to_string() }
}
```

使用例:
```moonbit
let visible = signal(true)
div(dyn_style=fn() { if visible.get() { "" } else { "display:none" } })
// または
div(dyn_class=dyn_show(class_signal))
```

## エスケープハッチ

DSL に未定義の属性は従来通り `attrs` / `dyn_attrs` で指定:

```moonbit
input(
  class="new-todo",
  attrs=[("autofocus", Attr::AttrBool(true))],
  dyn_attrs=[("aria-label", attr_dynamic(() => label.get()))],
)
```

## 実装方針

1. `scripts/generate_dom_elements.ts` を更新
   - `ElementAttr` に `hasDynamic?: boolean` を追加
   - 動的版パラメータを自動生成

2. `build_props` 関数を更新
   - 動的パラメータを `Dynamic()` として props に追加

3. `__generated.mbt` を再生成

4. 既存コード（TodoMVC 等）を新 DSL に移行

## 対象属性

### 共通（全要素）
- `class` → `dyn_class`
- `style` → `dyn_style`

### 要素固有
- `input`: `value`, `checked`, `disabled`
- `button`: `disabled`
- `a`: `href`
- その他、必要に応じて追加

## 互換性

- `dyn_attrs` は引き続きサポート（エスケープハッチとして）
- 既存コードは動作し続ける
- 段階的に新 DSL へ移行可能
