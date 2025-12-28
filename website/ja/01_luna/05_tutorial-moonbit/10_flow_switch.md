---
title: "制御フロー: Switch"
---

# Switch（複数条件）

複数の相互排他的な条件を処理します。

## 基本的な使い方

MoonBit ではパターンマッチングを使用して複数条件を処理：

```moonbit
using @server_dom { div, span, text }
using @luna { signal }

fn status_badge() -> @luna.Node {
  let status = signal("pending")

  div([
    match status.get() {
      "pending" => span(class_="yellow", [text("保留中")])
      "active" => span(class_="green", [text("アクティブ")])
      "error" => span(class_="red", [text("エラー")])
      _ => span([text("不明")])
    }
  ])
}
```

## 一般的なパターン

### タブコンテンツ

```moonbit
fn tab_view() -> @luna.Node {
  let tab = signal("overview")

  div([
    nav([
      button(onclick=fn() { tab.set("overview") }, [text("概要")]),
      button(onclick=fn() { tab.set("details") }, [text("詳細")]),
      button(onclick=fn() { tab.set("reviews") }, [text("レビュー")]),
    ]),
    match tab.get() {
      "overview" => overview_panel()
      "details" => details_panel()
      "reviews" => reviews_panel()
      _ => div([])
    }
  ])
}
```

### ステップウィザード

```moonbit
fn wizard() -> @luna.Node {
  let step = signal(1)

  div([
    match step.get() {
      1 => step1(on_next=fn() { step.set(2) })
      2 => step2(
        on_back=fn() { step.set(1) },
        on_next=fn() { step.set(3) },
      )
      3 => step3(
        on_back=fn() { step.set(2) },
        on_submit=handle_submit,
      )
      _ => div([])
    },
    p([text("ステップ " + step.get().to_string() + " / 3")]),
  ])
}
```

## 試してみよう

3つの状態（赤、黄、緑）を持つ信号機コンポーネントを作成し、それらを循環

## 次へ

[onMount →](./lifecycle_onmount) について学ぶ
