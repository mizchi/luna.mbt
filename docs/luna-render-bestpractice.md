# Luna Rendering Best Practices

大量のDOM要素を効率的に更新するためのベストプラクティス。

## 問題: 大量の動的要素

例: 100x100 (10,000セル) のグリッドゲーム

### アンチパターン: 個別の `attr_dynamic`

```moonbit
// BAD: 10,000個のeffectが作成される
fn render_grid(state_sig : @signal.Signal[GameState]) -> @dom.DomNode {
  @dom.for_each(
    fn() { indices },
    fn(i, _) {
      @dom.create_element(
        "div",
        [
          (
            "className",
            @dom.attr_dynamic(fn() {
              // 各セルごとにeffectが作成され、毎フレーム全て実行される
              cell_class(get_cell_type(x, y, state_sig.get()))
            }),
          ),
        ],
        [],
      )
    },
  )
}
```

**問題点:**
- 10,000個の独立したeffectが作成される
- Signal更新時に全effectが再実行される
- 結果: 76ms/frame (約13fps)

### 改善1: 単一effectでバッチ更新

```moonbit
// BETTER: 1つのeffectで全セルを更新
let cell_elements : Array[@js_dom.Element] = []

fn render_grid(state_sig : @signal.Signal[GameState]) -> @dom.DomNode {
  let _ = @signal.effect(fn() {
    let state = state_sig.get()
    for i = 0; i < cell_elements.length(); i = i + 1 {
      let x = i % GRID_SIZE
      let y = i / GRID_SIZE
      cell_elements[i].setClassName(cell_class(get_cell_type(x, y, state)))
    }
  })
  @dom.for_each(
    fn() { indices },
    fn(_, _) {
      @dom.div(
        class="cell c0",
        ref_=fn(el) { cell_elements.push(el) },
        [],
      )
    },
  )
}
```

**改善点:**
- effectが1つだけ
- `ref_` でDOM要素の参照を保持
- 直接 `setClassName` を呼び出し

### 改善2: Dirty Tracking (推奨)

```moonbit
// BEST: 変更があったセルだけ更新
let cell_elements : Array[@js_dom.Element] = []
let prev_cell_types : Array[Int] = []

fn render_grid(state_sig : @signal.Signal[GameState]) -> @dom.DomNode {
  // 前回の状態を初期化
  for i = 0; i < GRID_SIZE * GRID_SIZE; i = i + 1 {
    prev_cell_types.push(0)
  }

  let _ = @signal.effect(fn() {
    let state = state_sig.get()
    for i = 0; i < cell_elements.length(); i = i + 1 {
      let x = i % GRID_SIZE
      let y = i / GRID_SIZE
      let cell_type = get_cell_type(x, y, state)
      // 変更があった場合のみDOM更新
      if cell_type != prev_cell_types[i] {
        prev_cell_types[i] = cell_type
        cell_elements[i].setClassName(cell_class(cell_type))
      }
    }
  })

  @dom.for_each(
    fn() { indices },
    fn(_, _) {
      @dom.div(
        class="cell c0",
        ref_=fn(el) { cell_elements.push(el) },
        [],
      )
    },
  )
}
```

**結果: 0.7ms/frame (約1400fps相当)**

## パフォーマンス比較

| アプローチ | フレーム時間 | 理論FPS |
|-----------|------------|---------|
| 個別 attr_dynamic | 76ms | 13fps |
| 単一effect | ~10ms | 100fps |
| Dirty tracking | 0.7ms | 1400fps |

## 原則

### 1. Effect の数を最小化

```moonbit
// BAD: N個のeffect
for item in items {
  let _ = @signal.effect(fn() { ... })
}

// GOOD: 1個のeffect
let _ = @signal.effect(fn() {
  for item in items { ... }
})
```

### 2. DOM参照を保持して直接操作

```moonbit
// ref_ でDOM要素を取得
@dom.div(
  ref_=fn(el) { elements.push(el) },
  [],
)

// effect内で直接操作
el.setClassName(...)
el.setAttribute(...)
```

### 3. Dirty Tracking で差分更新

```moonbit
// 前回の状態を保持
let prev_state : Array[T] = []

// 変更時のみ更新
if current != prev_state[i] {
  prev_state[i] = current
  update_dom(...)
}
```

### 4. JS FFI でホットパスを最適化

```moonbit
// MoonBitの to_int() は重い
let x = pos.to_int()  // 遅い

// JS FFI でビット演算
extern "js" fn to_int_fast(x : Double) -> Int =
  #| (x) => x | 0

let x = to_int_fast(pos)  // 速い
```

## 適用場面

- ゲーム (大量のスプライト/タイル)
- データグリッド (大量の行/セル)
- 可視化 (大量のデータポイント)
- アニメーション (頻繁な更新)

## 注意点

- 通常のUIでは `attr_dynamic` で十分
- 最適化は計測してから行う
- 複雑さとパフォーマンスのトレードオフを考慮
