# MoonBit UI Library

純粋なMoonBitで実装された、React風のVirtual DOMライブラリです。

## 機能

- ✅ **Virtual DOM** - 効率的なDOM更新
- ✅ **Hooks API** - `useState`, `useEffect`, `useMemo`, `useCallback`, `useRef`
- ✅ **Component System** - 関数コンポーネントとHooksサポート
- ✅ **SSR (Server-Side Rendering)** - HTML文字列生成
- ✅ **Hydration** - SSRコンテンツのクライアント側復元
- ✅ **State Serialization** - Qwik風の状態シリアライズ（JS特化）
- ✅ **Type-safe Props** - 型安全なプロパティ

## 対応ターゲット

**JavaScript (Browser) のみ**

このライブラリはブラウザDOM専用です。詳細は [TARGET_SUPPORT.md](./TARGET_SUPPORT.md) を参照してください。

## テスト実行

```bash
# ✅ 正しい - jsターゲットでテスト
moon test --target js --package mizchi/ui

# 全111テストが成功します（コンポーネントテスト7件を含む）
```

## 使用例

### 基本的なコンポーネント

```moonbit
// カウンターコンポーネント
fn Counter() -> JSVNode {
  let (count, set_count) = use_state(0)

  div(
    [class_name("counter")],
    [
      text("Count: " + count.to_string()),
      button(
        [on_click(fn(_) { set_count(count + 1) })],
        [text("Increment")]
      )
    ]
  )
}

// レンダリング
let hooks_state = HooksState::new()
let vnode = component(Counter, None, hooks_state)
let rendered = render_component(vnode)

let renderer = DomRenderer::new(container_element)
renderer.render(rendered)
```

### プロパティ付きコンポーネント

```moonbit
struct GreetingProps {
  name : String
}

fn Greeting(props : GreetingProps) -> JSVNode {
  div([], [text("Hello, " + props.name)])
}

let hooks_state = HooksState::new()
let vnode = component_with_props(
  Greeting,
  { name: "Alice" },
  None,
  hooks_state
)
let rendered = render_component(vnode)
```

詳細は [RESUMABLE_STATE.md](./RESUMABLE_STATE.md) を参照してください。

## ドキュメント

- [RESUMABLE_STATE.md](./RESUMABLE_STATE.md) - 状態シリアライズの使い方
- [BACKEND_DEPENDENCY_ANALYSIS.md](./BACKEND_DEPENDENCY_ANALYSIS.md) - バックエンド依存性分析
- [TARGET_SUPPORT.md](./TARGET_SUPPORT.md) - ターゲットサポート情報
