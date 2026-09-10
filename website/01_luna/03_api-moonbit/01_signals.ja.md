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

## memo_eq

`memo` のカットオフは**同一性** (`physical_equal`) 判定です。再計算が前回と
同じオブジェクトを返したときだけ伝播を止めるので、毎回新しい値を確保する計算
— 組み立てた `String`、小さな構造体など — では、値が変わっていなくてもソース
が変わるたびに依存先が起きてしまいます。

`memo_eq` は `Eq` で比較します:

```moonbit
let n = @resource.signal(0)

// n が変わるたびに再実行される(毎回新しい String なので)
let loud = @resource.memo(fn() { "page \{n.get() / 100}" })

// ページ番号が実際に動いたときだけ再実行される
let quiet = @resource.memo_eq(fn() { "page \{n.get() / 100}" })
```

`memo` との違いは 2 点:

- **先行評価**。`memo` は最初の読み取り時に初めて本体を実行しますが、`memo_eq`
  は生成時に 1 回、以降はソースが変わるたびに実行します(読み手の有無に関係
  なく)。ソース 1 変更あたりの評価回数はどちらも 1 回です。
- **オーナー管理**。現在のオーナーに登録された effect を張るため、オーナーが
  破棄されると再計算を止め、以降は最後に公開した値を返し続けます。

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
