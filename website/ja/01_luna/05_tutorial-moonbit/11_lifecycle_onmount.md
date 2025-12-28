---
title: "ライフサイクル: onMount"
---

# onMount

コンポーネントが DOM にマウントされたときに一度だけコードを実行します。

## 基本的な使い方

```moonbit
using @luna { on_mount }

fn my_component() -> @luna.Node {
  on_mount(fn() {
    println("コンポーネントがマウントされました！")
  })

  div([text("Hello")])
}
```

## 一般的なユースケース

### 初期データのロード

```moonbit
fn user_profile(user_id : Int) -> @luna.Node {
  let user = signal(None : Option[User])
  let loading = signal(true)

  on_mount(fn() {
    fetch_user(user_id, fn(data) {
      user.set(Some(data))
      loading.set(false)
    })
  })

  show_node(
    when_=fn() { !loading.get() },
    fallback=spinner(),
    children=user_view(user.get().unwrap()),
  )
}
```

### サードパーティライブラリの初期化

```moonbit
fn chart(data : Array[DataPoint]) -> @luna.Node {
  on_mount(fn() {
    // DOM 準備完了後にチャートライブラリを初期化
    let chart = ChartLibrary::new(container_ref, data)

    on_cleanup(fn() {
      chart.destroy()
    })
  })

  div(ref_=container_ref, class_="chart-container", [])
}
```

## onMount vs effect

| 観点 | onMount | effect |
|------|---------|--------|
| 実行 | 一度 | 依存関係変更ごと |
| 依存関係追跡 | いいえ | はい |
| 用途 | セットアップ、初期化 | リアクティブな副作用 |

## 試してみよう

以下を行うコンポーネントを作成：
1. マウント時にデータをフェッチ
2. マウント時にログを記録

## 次へ

[onCleanup →](./lifecycle_oncleanup) について学ぶ
