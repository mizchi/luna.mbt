---
title: "制御フロー: Show"
---

# Show（条件付きレンダリング）

Signal に基づいてコンテンツを条件付きでレンダリングします。

## 基本的な使い方

```moonbit
using @server_dom { div, button, p, text, show_node }
using @luna { signal }

fn toggle() -> @luna.Node {
  let visible = signal(false)

  div([
    button([text("トグル")]),
    show_node(
      when_=fn() { visible.get() },
      fallback=p([text("非表示")]),
      children=p([text("表示されています！")]),
    ),
  ])
}
```

## 値の抽出

条件が値の場合、アクセスできます：

```moonbit
show_node(
  when_=fn() { user.get() },
  fallback=p([text("Loading...")]),
  children=fn(u) { p([text("Welcome, " + u.name + "!")]) },
)
```

## ネストした条件

```moonbit
show_node(
  when_=fn() { user.get() },
  fallback=guest_view(),
  children=show_node(
    when_=fn() { user.get().is_admin },
    fallback=user_dashboard(),
    children=admin_dashboard(),
  ),
)
```

## 一般的なパターン

### ローディング状態

```moonbit
show_node(
  when_=fn() { !loading.get() },
  fallback=spinner(),
  children=show_node(
    when_=fn() { error.get().is_none() },
    fallback=error_message(error.get()),
    children=data_view(data.get()),
  ),
)
```

## 試してみよう

認証状態に基づいて異なるコンテンツを表示するログイン/ログアウトトグルを作成

## 次へ

[For（リストレンダリング）→](./flow_for) について学ぶ
