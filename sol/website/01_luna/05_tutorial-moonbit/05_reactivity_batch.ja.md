---
title: "リアクティビティ: Batch"
---

# バッチ更新

複数の Signal 更新をバッチ処理して、Effect を一度だけトリガーします。

## 問題

バッチなしでは、各 Signal 更新が Effect を即座にトリガー：

```moonbit
let first_name = signal("John")
let last_name = signal("Doe")

effect(fn() {
  println("Name: " + first_name.get() + " " + last_name.get())
})

// 2つの別々の更新 = 2回の Effect 実行
first_name.set("Jane")  // Effect 実行
last_name.set("Smith")  // Effect 実行
```

## Batch の使用

```moonbit
using @luna { signal, effect, batch }

let first_name = signal("John")
let last_name = signal("Doe")

effect(fn() {
  println("Name: " + first_name.get() + " " + last_name.get())
})

// バッチ = 1回の Effect 実行
batch(fn() {
  first_name.set("Jane")
  last_name.set("Smith")
})
// Effect は一度だけ実行: "Jane Smith"
```

## Batch を使うタイミング

### 関連する複数の更新

```moonbit
let user = signal(None : Option[User])
let loading = signal(true)
let error = signal(None : Option[String])

fn on_success(data : User) {
  batch(fn() {
    user.set(Some(data))
    loading.set(false)
    error.set(None)
  })
}
```

### 状態マシン

```moonbit
let status = signal("idle")
let data = signal(None : Option[Data])
let progress = signal(0)

fn start_download() {
  batch(fn() {
    status.set("downloading")
    data.set(None)
    progress.set(0)
  })
}
```

## API サマリー

| 関数 | 説明 |
|-----|------|
| `batch(fn)` | 複数の更新をバッチ処理 |

## 試してみよう

RGB カラーピッカーを作成し、すべてのスライダーが変更されたときにプレビューを一度だけ更新

## 次へ

[Untrack →](./reactivity_untrack) について学ぶ
