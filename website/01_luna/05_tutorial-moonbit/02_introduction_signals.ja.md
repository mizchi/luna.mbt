---
title: "導入: Signals"
---

# Signals

Signal は値を保持し、変更時にサブスクライバーに通知するリアクティブコンテナです。

## Signal の作成

```moonbit
using @luna { signal }

let count = signal(0)
```

## 値の読み取り

`.get()` を使用して現在の値を読み取り：

```moonbit
let count = signal(0)
let value = count.get()  // 0
```

## 値の設定

`.set()` を使用して値を置き換え：

```moonbit
let count = signal(0)
count.set(5)
println(count.get())  // 5
```

## 値の更新

`.update()` を使用して現在の値に基づいて変換：

```moonbit
let count = signal(0)
count.update(fn(n) { n + 1 })
println(count.get())  // 1

count.update(fn(n) { n * 2 })
println(count.get())  // 2
```

## 追跡なしで覗く

`.peek()` を使用して依存関係を作成せずに読み取り：

```moonbit
let count = signal(0)

effect(fn() {
  // この Effect は count が変更されても再実行されない
  let value = count.peek()
  println("Peeked: " + value.to_string())
})
```

## 異なる型の Signal

```moonbit
// String Signal
let name = signal("Luna")
name.set("World")

// Boolean Signal
let visible = signal(true)
visible.set(false)

// 構造体 Signal
struct User {
  id : Int
  name : String
}

let user = signal(User { id: 1, name: "Alice" })
user.set(User { id: 2, name: "Bob" })
```

## コンポーネント内の Signal

```moonbit
using @server_dom { div, p, text }
using @luna { signal }

fn greeting() -> @luna.Node {
  let name = signal("World")

  div([
    p([text("Hello, " + name.get() + "!")]),
  ])
}
```

## API サマリー

| メソッド | 説明 |
|---------|------|
| `signal(value)` | 新しい Signal を作成 |
| `.get()` | 値を読み取り（依存関係を追跡） |
| `.set(value)` | 新しい値を設定 |
| `.update(fn)` | 現在の値に基づいて更新 |
| `.peek()` | 追跡なしで読み取り |

## TypeScript との比較

| TypeScript | MoonBit |
|------------|---------|
| `const [count, setCount] = createSignal(0)` | `let count = signal(0)` |
| `count()` | `count.get()` |
| `setCount(5)` | `count.set(5)` |
| `setCount(c => c + 1)` | `count.update(fn(n) { n + 1 })` |

## 試してみよう

以下を行う Signal を作成：
1. ユーザー名を保持
2. ユーザー名を更新
3. "Welcome, {username}!" を表示

## 次へ

[Effects →](./introduction_effects) について学ぶ
