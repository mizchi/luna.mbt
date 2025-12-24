---
title: チュートリアル (MoonBit)
---

# チュートリアル (MoonBit)

> TypeScript と MoonBit の両方の例を含む完全なチュートリアルは、[メインチュートリアル](/luna/tutorial-js/)を参照してください。

## MoonBit クイックスタート

`moon.mod.json` に Luna を追加:

```json
{
  "deps": {
    "mizchi/luna": "0.1.0"
  }
}
```

## 基本的なカウンター例

```moonbit
using @element {
  div, p, button, text, text_dyn, events,
  type DomNode,
}
using @luna { signal }

fn counter() -> DomNode {
  let count = signal(0)

  div([
    p([text_dyn(() => "Count: " + count.get().to_string())]),
    button(
      on=events().click(_ => count.update(n => n + 1)),
      [text("Increment")],
    ),
  ])
}
```

## TypeScript との違い

| TypeScript | MoonBit |
|------------|---------|
| `createSignal(0)` | `signal(0)` |
| `count()` | `count.get()` |
| `setCount(5)` | `count.set(5)` |
| `setCount(c => c + 1)` | `count.update(n => n + 1)` |
| `createEffect(() => ...)` | `effect(() => ...)` |
| `createMemo(() => ...)` | `memo(() => ...)` |

## 関連

- [チュートリアル](/luna/tutorial-js/) - 全トピックの完全なチュートリアル
- [Luna コア](/ja/luna/) - コア概念
- [Luna API](/ja/luna/signals/) - Signals API リファレンス
