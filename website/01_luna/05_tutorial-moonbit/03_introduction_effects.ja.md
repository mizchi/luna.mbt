---
title: "導入: Effects"
---

# Effects

Effect は依存関係が変更されたときに自動的に実行される関数です。

## Effect の作成

```moonbit
using @luna { signal, effect }

let count = signal(0)

effect(fn() {
  println("Count is: " + count.get().to_string())
})

// 出力: "Count is: 0"

count.set(1)
// 出力: "Count is: 1"
```

## 自動依存関係追跡

Effect は読み取った Signal を自動的に追跡：

```moonbit
let a = signal(1)
let b = signal(2)

effect(fn() {
  println("a: " + a.get().to_string())  // `a` のみ追跡
})

a.set(10)  // Effect 実行
b.set(20)  // Effect 実行されない（b は追跡されていない）
```

## 条件付き依存関係

依存関係は実行パスに基づいて動的に追跡：

```moonbit
let show_details = signal(false)
let name = signal("Luna")
let details = signal("A UI framework")

effect(fn() {
  println("Name: " + name.get())

  if show_details.get() {
    println("Details: " + details.get())  // show_details が true のときのみ追跡
  }
})

details.set("New details")  // Effect 実行されない

show_details.set(true)      // Effect 実行、`details` を追跡開始

details.set("Updated")      // Effect 実行
```

## 副作用

Effect は副作用に最適：

### ログ

```moonbit
let user = signal(None : Option[String])

effect(fn() {
  match user.get() {
    Some(name) => println("User logged in: " + name)
    None => ()
  }
})
```

## API サマリー

| 関数 | 説明 |
|-----|------|
| `effect(fn)` | リアクティブな副作用を作成 |
| `on_cleanup(fn)` | クリーンアップ関数を登録 |

## TypeScript との比較

| TypeScript | MoonBit |
|------------|---------|
| `createEffect(() => { ... })` | `effect(fn() { ... })` |
| `onCleanup(() => { ... })` | `on_cleanup(fn() { ... })` |

## 試してみよう

以下を行う Effect を作成：
1. `count` Signal を追跡
2. count が変更されるたびにログを記録
3. 前の値と新しい値を表示

## 次へ

[Memos →](./introduction_memos) について学ぶ
