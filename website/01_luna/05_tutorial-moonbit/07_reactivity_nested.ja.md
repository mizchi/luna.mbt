---
title: "リアクティビティ: ネストした Effects"
---

# ネストした Effects

Effect をネストしてスコープ付きリアクティブコンテキストを作成できます。

## Effect の所有権

別の Effect 内で Effect を作成すると、内側の Effect は外側の「所有」になります：

```moonbit
let show_panel = signal(false)
let count = signal(0)

effect(fn() {
  if show_panel.get() {
    println("Panel shown")

    // この Effect は show_panel が true の間のみ存在
    effect(fn() {
      println("Count: " + count.get().to_string())
    })
  }
})

show_panel.set(true)   // "Panel shown", "Count: 0"
count.set(1)           // "Count: 1"
show_panel.set(false)  // "Panel shown"（内側の Effect は破棄）
count.set(2)           // 何も出力されない
```

## 自動クリーンアップ

外側の Effect が再実行されると、すべての内側の Effect は自動的に破棄されます。

## ユースケース

### 条件付き購読

```moonbit
let is_logged_in = signal(false)
let notifications = signal([])

effect(fn() {
  if is_logged_in.get() {
    // ログイン時のみ通知を購読
    effect(fn() {
      let notifs = notifications.get()
      update_notification_badge(notifs.length())
    })
  }
})
```

## 試してみよう

各タブが独自のカウンターを持ち、そのタブがアクティブな間のみ追跡される「タブ」コンポーネントを作成

## 次へ

[Show（条件付きレンダリング）→](./flow_show) について学ぶ
