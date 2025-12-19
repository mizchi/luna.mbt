---
title: はじめに
---

# はじめに

Lunaのインストールと最初のコンポーネント作成を学びます。

## インストール

### npm (JavaScript/TypeScript向け)

```bash
npm install @mizchi/luna
```

### MoonBit

`moon.mod.json` に追加:

```json
{
  "deps": {
    "mizchi/luna": "0.1.0"
  }
}
```

## 最初のコンポーネント

### TypeScript/JSXで

```tsx
import { createSignal } from '@mizchi/luna';

function Counter() {
  const [count, setCount] = createSignal(0);

  return (
    <div>
      <p>Count: {count()}</p>
      <button onClick={() => setCount(c => c + 1)}>
        Increment
      </button>
    </div>
  );
}
```

### MoonBitで

```moonbit
fn counter() -> @element.DomNode {
  let count = @luna.signal(0)

  @element.div([
    @element.p([@element.text_dyn(fn() { "Count: \{count.get()}" })]),
    @element.button(
      on=@element.events().click(fn(_) { count.update(fn(n) { n + 1 }) }),
      [@element.text("Increment")],
    ),
  ])
}
```

## 次のステップ

- [Signals](/ja/guide/signals) - リアクティブプリミティブを学ぶ
- [Island Architecture](/ja/guide/islands) - 部分的ハイドレーションのパターン
- [パフォーマンス](/ja/performance/) - ベンチマークと最適化
