---
title: "ライフサイクル: onCleanup"
---

# onCleanup

コンポーネントがアンマウントされるか Effect が再実行されるときに実行されるクリーンアップ関数を登録します。

## 基本的な使い方

```moonbit
using @luna { signal, on_cleanup }

fn timer() -> @luna.Node {
  let count = signal(0)

  let interval = set_interval(1000, fn() {
    count.update(fn(c) { c + 1 })
  })

  // コンポーネントアンマウント時にクリーンアップ
  on_cleanup(fn() {
    clear_interval(interval)
  })

  p([text("Count: " + count.get().to_string())])
}
```

## onCleanup が実行されるタイミング

### コンポーネント内

コンポーネントが DOM から削除されるときに実行。

### Effect 内

Effect が再実行または破棄される前に実行：

```moonbit
let url = signal("/api/data")

effect(fn() {
  let current_url = url.get()
  let controller = AbortController::new()

  fetch(current_url, controller.signal)

  // url が変更されたとき（次の fetch 前）にクリーンアップ実行
  on_cleanup(fn() {
    controller.abort()
  })
})
```

## 一般的なユースケース

### タイマー

```moonbit
fn countdown(seconds : Int) -> @luna.Node {
  let remaining = signal(seconds)

  let interval = set_interval(1000, fn() {
    remaining.update(fn(r) {
      if r <= 0 { 0 } else { r - 1 }
    })
  })

  on_cleanup(fn() { clear_interval(interval) })

  p([text(remaining.get().to_string() + " 秒")])
}
```

### イベントリスナー

```moonbit
fn window_resize() -> @luna.Node {
  let size = signal({ width: window_inner_width(), height: window_inner_height() })

  let handler = fn() {
    size.set({ width: window_inner_width(), height: window_inner_height() })
  }

  window_add_event_listener("resize", handler)

  on_cleanup(fn() {
    window_remove_event_listener("resize", handler)
  })

  p([text("ウィンドウ: " + size.get().width.to_string() + "x" + size.get().height.to_string())])
}
```

## よくある間違い

### クリーンアップの忘れ

```moonbit
// 悪い: メモリリーク！
fn bad_component() -> @luna.Node {
  set_interval(1000, fn() {
    println("アンマウント後も実行中！")
  })
  div([])
}

// 良い: 適切なクリーンアップ
fn good_component() -> @luna.Node {
  let interval = set_interval(1000, fn() {
    println("アンマウント時にクリーンアップ")
  })
  on_cleanup(fn() { clear_interval(interval) })
  div([])
}
```

## 試してみよう

以下を行うコンポーネントを作成：
1. 接続を開く
2. 受信データを表示
3. アンマウント時に接続を適切に閉じる

## 次へ

[Islands アーキテクチャ →](./islands_basics) について学ぶ
