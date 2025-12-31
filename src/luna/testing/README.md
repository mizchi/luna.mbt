# Luna Testing

Luna UI コンポーネントをユニットテストするためのヘルパーライブラリ。
DOM非依存でVNode構造を直接テストできる。

## 概要

このパッケージは `@luna/testing` として Luna 本体へ提案予定のプロトタイプ実装。

## 機能

### Query Helpers (`query.mbt`)

VNode構造をクエリするためのヘルパー関数。

```moonbit
// 基本クエリ
get_element(node)      // Element を取得
get_text(node)         // Text コンテンツを取得
get_dynamic_text(node) // DynamicText の現在値を取得
get_tag(node)          // タグ名を取得
child_count(node)      // 子要素数を取得
get_children(node)     // 子要素を取得（Show/For/Component 透過）

// 属性クエリ
get_attr(node, name)         // 属性を取得
get_static_attr(node, name)  // 静的属性値を取得
get_dynamic_attr(node, name) // 動的属性の現在値を取得
get_attr_value(node, name)   // 属性値を取得（両対応）
get_handler(node, name)      // イベントハンドラを取得
has_handler(node, name)      // ハンドラの存在確認
get_attr_names(node)         // 全属性名を取得

// 検索
find_by_tag(node, tag)              // タグ名で検索
find_all_by_tag(node, tag)          // タグ名で全検索
find_by_attr(node, name, value)     // 属性値で検索
find_by(node, predicate)            // 述語関数で検索
find_all_by(node, predicate)        // 述語関数で全検索

// テキスト
get_all_text(node)          // 全テキストを取得
contains_text(node, text)   // テキスト含有確認

// 型判定
node_type_name(node)  // タイプ名を取得
is_element(node)      // Element判定
is_text(node)         // Text判定
is_dynamic_text(node) // DynamicText判定
is_fragment(node)     // Fragment判定
is_show(node)         // Show判定
is_for(node)          // For判定
is_component(node)    // Component判定
```

### Assertion Helpers (`assertions.mbt`)

テスト用アサーション関数。失敗時は `abort` で即座に停止。

```moonbit
// タグ
assert_tag(node, expected)
assert_is_element(node)
assert_is_text(node)

// 属性
assert_static_attr(node, name, expected)
assert_dynamic_attr(node, name, expected)
assert_attr(node, name, expected)
assert_has_attr(node, name)
assert_has_handler(node, name)

// テキスト
assert_text(node, expected)
assert_text_contains(node, expected)
assert_text_not_contains(node, unexpected)

// 構造
assert_child_count(node, expected)
assert_has_element(node, tag)
assert_no_element(node, tag)
assert_element_count(node, tag, expected)

// Show/For
assert_show_visible(node)
assert_show_hidden(node)
assert_for_count(node, expected)
```

### Signal Helpers (`signal.mbt`)

Signal のリアクティビティをテストするためのユーティリティ。

```moonbit
// Signal トラッキング
let tracker = track_signal(sig)
tracker_values(tracker)  // 値履歴を取得
tracker_last(tracker)    // 最後の値を取得
tracker_count(tracker)   // 変更回数を取得
tracker_stop(tracker)    // トラッキング停止

// Effect カウント
let counter = count_effect(fn() { ... })
effect_get_count(counter)
effect_reset(counter)
effect_stop(counter)

// バッチテスト
test_batch(setup, updates, verify)

// アサーション
assert_signal_value(sig, expected)
assert_tracked_values(tracker, expected)
assert_effect_count(counter, expected)
```

## 使用例

```moonbit
test "component updates on signal change" {
  let count = @signal.signal(0)
  let node : @luna.Node[Unit] = @luna.h("div", [], [
    @luna.text_dyn(fn() { "Count: " + count.get().to_string() })
  ])

  // 初期値を検証
  assert_text_contains(node, "Count: 0")

  // Signal を更新
  count.set(5)

  // 動的テキストが更新されることを検証
  assert_text_contains(node, "Count: 5")
}

test "conditional rendering with Show" {
  let visible = @signal.signal(false)
  let node : @luna.Node[Unit] = @luna.show(
    fn() { visible.get() },
    fn() { @luna.h("button", [], [@luna.text("Click")]) }
  )

  // 非表示時はボタンが見つからない
  assert_true(find_by_tag(node, "button") is None)

  // 表示時はボタンが見つかる
  visible.set(true)
  assert_has_element(node, "button")
}
```

## Luna への提案

このパッケージが安定したら `@luna/testing` として Luna 本体へ提案予定。
設計詳細は `docs/proposal-luna-ui-testing.md` を参照。
