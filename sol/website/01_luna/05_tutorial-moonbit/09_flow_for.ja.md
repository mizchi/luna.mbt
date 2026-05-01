---
title: "制御フロー: For"
---

# For（リストレンダリング）

リアクティブな更新で効率的にリストをレンダリングします。

## 基本的な使い方

```moonbit
using @server_dom { ul, li, text, for_each }
using @luna { signal }

fn todo_list() -> @luna.Node {
  let todos = signal([
    { id: 1, text: "Luna を学ぶ" },
    { id: 2, text: "アプリを作る" },
    { id: 3, text: "デプロイ" },
  ])

  ul([
    for_each(
      items=fn() { todos.get() },
      render=fn(todo, _idx) {
        li([text(todo.text)])
      },
    ),
  ])
}
```

## インデックス付き

現在のインデックスにアクセス：

```moonbit
for_each(
  items=fn() { items.get() },
  render=fn(item, idx) {
    li([text((idx() + 1).to_string() + ". " + item.name)])
  },
)
```

## 空リストのフォールバック

```moonbit
for_each(
  items=fn() { items.get() },
  fallback=p([text("アイテムがありません。")]),
  render=fn(item, _) { item_view(item) },
)
```

## リストの更新

### アイテム追加

```moonbit
fn add_item() {
  todos.update(fn(prev) {
    prev.push({ id: next_id(), text: "New Item" })
    prev
  })
}
```

### アイテム削除

```moonbit
fn remove_item(id : Int) {
  todos.update(fn(prev) {
    prev.filter(fn(item) { item.id != id })
  })
}
```

## 試してみよう

以下を持つ Todo リストを作成：
1. 新しい Todo を追加する入力
2. クリックで完了をトグル
3. 完了済みを削除するボタン

## 次へ

[Switch →](./flow_switch) について学ぶ
