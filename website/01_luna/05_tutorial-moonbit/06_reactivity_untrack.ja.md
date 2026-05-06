---
title: "リアクティビティ: Untrack"
---

# Untrack

依存関係を作成せずに Signal を読み取ります。

## 問題

Signal の値を読み取りたいが、その変更を購読したくない場合があります：

```moonbit
let count = signal(0)
let multiplier = signal(2)

effect(fn() {
  // この Effect は count か multiplier のどちらかが変更されると実行
  println((count.get() * multiplier.get()).to_string())
})
```

## Untrack の使用

```moonbit
using @luna { signal, effect, untrack }

let count = signal(0)
let multiplier = signal(2)

effect(fn() {
  // `count` のみ追跡、`multiplier` は追跡しない
  let mult = untrack(fn() { multiplier.get() })
  println((count.get() * mult).to_string())
})

count.set(5)        // Effect 実行: 10
multiplier.set(3)   // Effect 実行されない
count.set(6)        // Effect 実行: 18
```

## 一般的なユースケース

### 値の比較

```moonbit
let current = signal(0)
let previous = signal(0)

effect(fn() {
  let curr = current.get()

  // 追跡せずに前の値と比較
  let prev = untrack(fn() { previous.get() })

  if curr != prev {
    println("Changed from " + prev.to_string() + " to " + curr.to_string())
    previous.set(curr)
  }
})
```

### 購読なしのログ

```moonbit
let user = signal(None : Option[User])

effect(fn() {
  match user.get() {
    Some(u) => {
      // 購読せずに他の状態をログ
      untrack(fn() {
        println("User logged in: " + u.name)
        println("Current page: " + page.get())
      })
    }
    None => ()
  }
})
```

## API サマリー

| 関数 | 説明 |
|-----|------|
| `untrack(fn)` | 依存関係を追跡せずにコードを実行 |

## 試してみよう

`count` が変更されたときにログを記録し、`timestamp` も含めるが、`count` の変更時のみ再実行する Effect を作成

## 次へ

[ネストした Effects →](./reactivity_nested) について学ぶ
