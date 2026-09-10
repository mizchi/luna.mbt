---
title: Signals
---

# Signals

Signals は Luna のリアクティビティシステムの基盤です。

以下の例は `@resource` エイリアスを使います。パッケージの `moon.pkg` でインポートを宣言してください:

```
import {
  "mizchi/luna/js/resource",
}
```

`sol new` が生成するプロジェクトでは `"mizchi/signals" @signal` が宣言済みなので、そちらでは `@signal.signal(...)` と書きます。どちらも同じ実体です(`@resource` は `mizchi/signals` を再エクスポートしています)。以下ではプレフィックスを省いて書きます。

## Signal

値を保持するリアクティブなセルを作ります。

```moonbit
let count = Signal::new(0)

// 読み取り(依存を登録する)
let value = count.get()  // 0

// 書き込み
count.set(5)

// 現在値をもとに更新
count.update(fn(n) { n + 1 })

// 追跡せずに読む
let peeked = count.peek()
```

`Signal::new(0)` と `signal(0)` は同じものです。

### コンストラクタ

```moonbit
fn Signal::new[T](value : T) -> Signal[T]
```

### メソッド

| メソッド | 説明 |
|----------|------|
| `.get()` | 値を読む(依存を登録) |
| `.set(value)` | 新しい値を設定 |
| `.update(fn)` | 現在値をもとに更新 |
| `.peek()` | 追跡せずに読む |
| `.subscriber_count()` | 購読者数 |
| `.clear_subscribers()` | 購読者を全解除 |

### 変換

これらは `Signal` のメソッドではなく、自由関数です:

```moonbit
let count = Signal::new(5)

// 派生ゲッターへの map
let doubled = sig_map(count, fn(n) { n * 2 })
assert_eq(doubled(), 10)

// フィルタ — Option の Signal になる
let positive = sig_filter(count, fn(n) { n > 0 })
assert_eq(positive.peek(), Some(5))

// フィルタと map を同時に
let doubled_positive = sig_filter_map(count, fn(n) {
  if n > 0 { Some(n * 2) } else { None }
})
assert_eq(doubled_positive.peek(), Some(10))

// 読み取り専用ビュー
let getter = to_getter(count)
assert_eq(getter(), 5)
```

| 関数 | 戻り値 |
|------|--------|
| `sig_map(signal, fn)` | `() -> U` |
| `sig_filter(signal, pred)` | `Signal[T?]` |
| `sig_filter_map(signal, fn)` | `Signal[U?]` |
| `to_getter(signal)` | `() -> T` |

## effect

依存を自動追跡する副作用を作ります。

```moonbit
let name = Signal::new("Luna")

let dispose = effect(fn() {
  println("Hello, \{name.get()}!")
})
// 出力: Hello, Luna!

name.set("World")
// 出力: Hello, World!

dispose()  // effect を停止
```

### シグネチャ

```moonbit
fn effect(fn : () -> Unit) -> () -> Unit
```

### バリエーション

```moonbit
// 条件付き effect — 条件が true のときだけ実行
let condition = Signal::new(false)
effect_when(fn() { condition.get() }, fn() {
  println("Condition is true!")
})

// 1 回だけの effect — 実行後に自動で dispose
effect_once(fn() {
  println("This runs only once")
})
```

`render_effect` は同期実行版で、luna の `Show` / `For` などのプリミティブが内部で使います。アプリケーションコードでは `effect` を既定にしてください。

## memo / computed

派生値をキャッシュします。依存する Signal が変わったときだけ再計算されます。

```moonbit
let count = Signal::new(2)
let doubled = memo(fn() { count.get() * 2 })

assert_eq(doubled(), 4)

count.set(3)
assert_eq(doubled(), 6)

// `computed` は `memo` の別名
let tripled = computed(fn() { count.get() * 3 })
```

### シグネチャ

```moonbit
fn memo[T](fn : () -> T) -> () -> T
fn computed[T](fn : () -> T) -> () -> T
```

## memo_eq

`memo` のカットオフは**同一性** (`physical_equal`) 判定です。再計算が前回と同じオブジェクトを返したときだけ伝播を止めるので、毎回新しい値を確保する計算 — 組み立てた `String`、小さな構造体など — では、値が変わっていなくてもソースが変わるたびに依存先が起きてしまいます。

`memo_eq` は `Eq` で比較します:

```moonbit
let n = @resource.signal(0)

// n が変わるたびに再実行される(毎回新しい String なので)
let loud = @resource.memo(fn() { "page \{n.get() / 100}" })

// ページ番号が実際に動いたときだけ再実行される
let quiet = @resource.memo_eq(fn() { "page \{n.get() / 100}" })
```

`memo` との違いは 2 点:

- **先行評価**。`memo` は最初の読み取り時に初めて本体を実行しますが、`memo_eq` は生成時に 1 回、以降はソースが変わるたびに実行します(読み手の有無に関係なく)。ソース 1 変更あたりの評価回数はどちらも 1 回です。
- **オーナー管理**。現在のオーナーに登録された effect を張るため、オーナーが破棄されると再計算を止め、以降は最後に公開した値を返し続けます。

### シグネチャ

```moonbit
fn memo_eq[T : Eq](fn : () -> T) -> () -> T
```

## batch

複数の更新をまとめ、effect の実行を 1 回に畳みます。

```moonbit
let a = Signal::new(0)
let b = Signal::new(0)

batch(fn() {
  a.set(1)
  b.set(2)
})
// 両方を読む effect は 1 回だけ実行される
```

`batch_start()` / `batch_end()` で明示的に区間を作ることもできます。`is_batching()` で現在バッチ中かを確認できます。

## untracked

Signal の読み取りを依存追跡から外します。

```moonbit
let a = Signal::new(0)
let b = Signal::new(0)

effect(fn() {
  let val_a = a.get()
  let val_b = untracked(fn() { b.get() })
  println("\{val_a}, \{val_b}")
})
// a が変わったときだけ実行される
```

意図した依存まで `untracked` の内側に入れないよう注意してください。効かせたい `get()` は `untracked` の外に置きます。

## on_cleanup

現在の effect に対するクリーンアップを登録します。

```moonbit
let active = Signal::new(true)

effect(fn() {
  if active.get() {
    println("Starting...")
    on_cleanup(fn() {
      println("Cleaning up...")
    })
  }
})
```

### クリーンアップが走るタイミング

- effect が再実行される直前
- effect が dispose されたとき
- 登録と逆順(LIFO)

## 購読 API

### on / on_immediate

Signal の変更を購読します。

```moonbit
let sig = Signal::new(0)

// 変更を購読(初期値では呼ばれない)
let unsub = on(sig, fn(value) {
  println("Changed to: \{value}")
})

sig.set(1)  // 出力: Changed to: 1
sig.set(2)  // 出力: Changed to: 2
unsub()     // 購読解除
sig.set(3)  // 何も出力されない

// 初期値でも即座に呼ぶ
on_immediate(sig, fn(value) {
  println("Value: \{value}")
})
// 即座に出力: Value: 3
```

### watch / watch_immediate

計算式を監視し、値が変わったときにコールバックを呼びます。

```moonbit
let sig = Signal::new(0)

// 変更を監視(旧値も受け取る)
watch(fn() { sig.get() }, fn(new_val, old_val) {
  println("Changed from \{old_val} to \{new_val}")
})

sig.set(1)  // 出力: Changed from 0 to 1

// 初回も呼ぶ版(初回の old_val は None)
watch_immediate(fn() { sig.get() }, fn(new_val, old_val) {
  match old_val {
    Some(old) => println("Changed from \{old} to \{new_val}")
    None => println("Initial value: \{new_val}")
  }
})
```

`watch` の比較は `Eq` なので、値が構造的に等しければコールバックは呼ばれません。

### previous

Signal の前回値を保持します。

```moonbit
let sig = Signal::new(1)
let prev = previous(sig)

assert_eq(prev(), None)  // まだ前回値がない
sig.set(2)
assert_eq(prev(), Some(1))
sig.set(3)
assert_eq(prev(), Some(2))

// 初期値付き版
let prev_with_init = previous_with_initial(sig, 0)
assert_eq(prev_with_init(), 3)
```

## コンビネータ

### combine

複数の Signal を合成します。

```moonbit
let a = Signal::new(1)
let b = Signal::new(2)
let c = Signal::new(3)

// 2 つ
let sum2 = combine2(a, b, fn(x, y) { x + y })
assert_eq(sum2(), 3)

// 3 つ
let sum3 = combine3(a, b, c, fn(x, y, z) { x + y + z })
assert_eq(sum3(), 6)

// 4 つの combine4(a, b, c, d, fn) もあります
```

### all / any

Signal の配列に対する真偽値コンビネータ。

```moonbit
let a = Signal::new(true)
let b = Signal::new(true)
let c = Signal::new(false)

let all_true = all([a, b])
assert_eq(all_true(), true)

let all_true2 = all([a, b, c])
assert_eq(all_true2(), false)

let any_true = any([a, c])
assert_eq(any_true(), true)
```

### switch_

条件によって 2 つの Signal を切り替えます。

```moonbit
let cond = Signal::new(true)
let on_true = Signal::new("yes")
let on_false = Signal::new("no")

let result = switch_(cond, on_true, on_false)
assert_eq(result(), "yes")

cond.set(false)
assert_eq(result(), "no")
```

### select

配列からインデックスで要素を選びます。

```moonbit
let items = Signal::new([10, 20, 30, 40])
let index = Signal::new(1)

let selected = select(items, index)
assert_eq(selected(), Some(20))

index.set(5)  // 範囲外
assert_eq(selected(), None)
```

### flatten

ネストした Signal を平坦化します。

```moonbit
let inner = Signal::new(10)
let outer = Signal::new(inner)

let flattened = flatten(outer)
assert_eq(flattened(), 10)

inner.set(20)
assert_eq(flattened(), 20)

// 内側の Signal を差し替えても追随する
let new_inner = Signal::new(30)
outer.set(new_inner)
assert_eq(flattened(), 30)
```

## オーナー / スコープ管理

### create_root

ネストした effect をまとめて破棄できるルートスコープを作ります。

```moonbit
let sig = Signal::new(0)
let effect_count = { val: 0 }

create_root(fn(dispose) {
  effect(fn() {
    let _ = sig.get()
    effect_count.val = effect_count.val + 1
  })

  sig.set(1)  // effect_count = 2
  dispose()   // 内側の effect をすべて破棄
})

sig.set(2)  // effect は実行されない
```

### create_root_with_dispose

結果と dispose 関数の両方を返します。

```moonbit
let (result, dispose) = create_root_with_dispose(fn() {
  register_owner_cleanup(fn() { println("Cleanup!") })
  42
})
assert_eq(result, 42)
dispose()  // 出力: Cleanup!
```

### オーナーのユーティリティ

```moonbit
// オーナースコープの内側かどうか
assert_false(has_owner())  // create_root の外では false

create_root(fn(_) {
  assert_true(has_owner())  // 内側では true

  // 現在のオーナーを取得
  let owner = get_owner()

  // 保存したオーナーの下で後から実行
  match owner {
    Some(o) => run_with_owner(o, fn() {
      // オーナーのコンテキストにアクセスできる
    })
    None => ()
  }
})
```

### on_mount

依存を追跡せずに 1 回だけ実行します(SolidJS の onMount 相当)。

```moonbit
let sig = Signal::new(0)

create_root(fn(_) {
  on_mount(fn() {
    let _ = sig.get()  // 依存にならない
    println("Mounted!")
  })
})

sig.set(1)  // on_mount は再実行されない
```

## Context API

コンポーネントツリーを通して値を渡します。

```moonbit
// 既定値付きで context を作る
let theme_ctx = create_context("light")

// 未提供なら既定値が返る
assert_eq(use_context(theme_ctx), "light")

// スコープ内で値を提供する
let result = provide(theme_ctx, "dark", fn() {
  use_context(theme_ctx)  // "dark"
})
assert_eq(result, "dark")

// ネストした provide
provide(theme_ctx, "outer", fn() {
  println(use_context(theme_ctx))  // "outer"
  provide(theme_ctx, "inner", fn() {
    println(use_context(theme_ctx))  // "inner"
  })
  println(use_context(theme_ctx))  // 再び "outer"
})
```

## Resource API

非同期処理を loading / error 状態つきで扱います。

### 解決済み / 失敗済み

```moonbit
// 解決済みの Resource
let res = resource_resolved(42)
assert_true(res.is_success())
assert_eq(res.value(), Some(42))

// 失敗済みの Resource
let err_res : Resource[Int] = resource_rejected("error")
assert_true(err_res.is_failure())
assert_eq(err_res.error(), Some("error"))
```

### deferred(手動制御)

```moonbit
let (res, resolve, reject) : (Resource[Int], (Int) -> Unit, (String) -> Unit) = deferred()

assert_true(res.is_pending())

resolve(100)
assert_true(res.is_success())
assert_eq(res.value(), Some(100))

// あるいは:
// reject("Failed!")
// assert_true(res.is_failure())

// refetch で pending に戻る
res.refetch()
assert_true(res.is_pending())
```

### Resource のメソッド

| メソッド | 説明 |
|----------|------|
| `.is_pending()` | 読み込み中なら true |
| `.is_success()` | 解決済みなら true |
| `.is_failure()` | 失敗なら true |
| `.value()` | 解決値(Option) |
| `.error()` | エラーメッセージ(Option) |
| `.peek()` | 追跡せずに状態を取得 |
| `.refetch()` | pending に戻す |

## API まとめ

### コア

| 関数 | 説明 |
|------|------|
| `Signal::new(value)` | リアクティブな Signal を作成 |
| `effect(fn)` | 副作用を作成(dispose を返す) |
| `effect_when(cond, fn)` | 条件付き effect |
| `effect_once(fn)` | 1 回だけの effect |
| `memo(fn)` / `computed(fn)` | キャッシュ付き派生値(同一性カットオフ) |
| `memo_eq(fn)` | `Eq` カットオフの派生値 |
| `batch(fn)` | 更新をまとめる |
| `untracked(fn)` | 追跡せずに実行 |
| `on_cleanup(fn)` | クリーンアップを登録 |

### 購読

| 関数 | 説明 |
|------|------|
| `on(signal, fn)` | 変更を購読 |
| `on_immediate(signal, fn)` | 初期値でも呼ぶ購読 |
| `watch(getter, callback)` | 計算値を監視 |
| `watch_immediate(getter, callback)` | 初回も呼ぶ監視 |
| `previous(signal)` | 前回値を保持 |

### コンビネータ

| 関数 | 説明 |
|------|------|
| `sig_map` / `sig_filter` / `sig_filter_map` | Signal / ゲッターを派生 |
| `to_getter(signal)` | 読み取り専用ゲッター |
| `combine2/3/4(signals, fn)` | Signal を合成 |
| `all(signals)` | すべて true か |
| `any(signals)` | いずれか true か |
| `switch_(cond, a, b)` | 条件で選択 |
| `select(items, index)` | インデックスで選択 |
| `flatten(nested)` | ネストを平坦化 |

### オーナー / Context

| 関数 | 説明 |
|------|------|
| `create_root(fn)` | リアクティブスコープを作成 |
| `create_root_with_dispose(fn)` | (結果, dispose) を返す |
| `get_owner()` | 現在のオーナーを取得 |
| `run_with_owner(owner, fn)` | オーナーの下で実行 |
| `has_owner()` | オーナーの有無 |
| `on_mount(fn)` | 追跡せずに 1 回実行 |
| `create_context(default)` | context を作成 |
| `use_context(ctx)` | context の値を取得 |
| `provide(ctx, value, fn)` | context を提供 |

### Resource

| 関数 | 説明 |
|------|------|
| `resource_resolved(value)` | 解決済み Resource |
| `resource_rejected(error)` | 失敗済み Resource |
| `deferred()` | 手動制御の Resource |
