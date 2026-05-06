---
title: "導入: Memos"
---

# Memos（計算値）

Memo は結果をキャッシュし、依存関係が変更されたときのみ再計算する派生値です。

## Memo の作成

```moonbit
using @luna { signal, memo }

let count = signal(2)

// count に依存する計算値
let doubled = memo(fn() { count.get() * 2 })

println(doubled())  // 4

count.set(5)
println(doubled())  // 10
```

## Memo はキャッシュされる

Memo は依存関係が変更されたときのみ再計算：

```moonbit
let count = signal(0)
let other = signal(0)

let expensive = memo(fn() {
  println("Computing...")
  count.get() * 2
})

expensive()  // "Computing..." を出力、0 を返す
expensive()  // 出力なし（キャッシュ）、0 を返す

other.set(5)  // 再計算をトリガーしない
expensive()   // 出力なし（キャッシュ）、0 を返す

count.set(1)  // 再計算をトリガー
expensive()   // "Computing..." を出力、2 を返す
```

## チェーンされた Memo

Memo は他の Memo に依存できる：

```moonbit
let price = signal(100)
let quantity = signal(2)
let tax_rate = signal(0.1)

let subtotal = memo(fn() { price.get() * quantity.get() })
let tax = memo(fn() { subtotal() * tax_rate.get() })
let total = memo(fn() { subtotal() + tax() })

println(total())  // 220

quantity.set(3)
println(total())  // 330
```

## Memo vs Effect

| 観点 | Memo | Effect |
|------|------|--------|
| 値を返す | はい | いいえ |
| 結果をキャッシュ | はい | いいえ |
| 用途 | 派生データ | 副作用 |

```moonbit
// 計算値には Memo を使用
let doubled = memo(fn() { count.get() * 2 })

// 副作用には Effect を使用
effect(fn() {
  println("Count changed: " + count.get().to_string())
})
```

## API サマリー

| 関数 | 説明 |
|-----|------|
| `memo(fn)` | キャッシュされた派生値を作成 |

## TypeScript との比較

| TypeScript | MoonBit |
|------------|---------|
| `createMemo(() => count() * 2)` | `memo(fn() { count.get() * 2 })` |

## 試してみよう

ショッピングカートを作成：
1. `price` と `quantity` の Signal
2. `subtotal` Memo
3. `tax` Memo（10%）
4. `total` Memo

## 次へ

[バッチ更新 →](./reactivity_batch) について学ぶ
