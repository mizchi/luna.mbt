---
title: Signals
---

# Signals

Signals は Luna のリアクティビティシステムの基盤です。

## signal

リアクティブな値を作成します。

```moonbit
let count = @signal.signal(0)

// 読み取り
println(count.get().to_string())  // 0

// 書き込み
count.set(1)

// 更新
count.update(fn(n) { n + 1 })
```

## effect

Signal の変更に反応する副作用を作成します。

```moonbit
let count = @signal.signal(0)

@signal.effect(fn() {
  println("Count changed: " + count.get().to_string())
})

count.set(1)  // 出力: Count changed: 1
```

## memo

派生値を計算します。依存する Signal が変更されたときのみ再計算されます。

```moonbit
let count = @signal.signal(2)
let doubled = @signal.memo(fn() { count.get() * 2 })

println(doubled().to_string())  // 4
count.set(3)
println(doubled().to_string())  // 6
```

## batch

複数の更新をバッチ処理します。

```moonbit
let a = @signal.signal(0)
let b = @signal.signal(0)

@signal.batch(fn() {
  a.set(1)
  b.set(2)
})
// Effect は1回だけ実行される
```

## untrack

Signal の読み取りを追跡から除外します。

```moonbit
let a = @signal.signal(0)
let b = @signal.signal(0)

@signal.effect(fn() {
  let val_a = a.get()
  let val_b = @signal.untrack(fn() { b.get() })
  println("\{val_a}, \{val_b}")
})
// a が変更されたときのみ実行される
```
