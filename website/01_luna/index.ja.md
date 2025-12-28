---
title: Luna UI
---

# Luna UI

Luna はMoonBitとJavaScriptのためのリアクティブUIライブラリです。Fine-grained reactivityとIsland Architectureを特徴としています。

## クイックスタート

### JavaScript/TypeScript

```bash
npx @luna_ui/luna new myapp
cd myapp && npm install && npm run dev
```

### MoonBit

```bash
npx @luna_ui/luna new myapp --mbt
cd myapp && moon update && npm install && npm run dev
```

## コア概念

### Signals

Signalsはlunaのリアクティビティシステムの基盤です。

```typescript
import { createSignal, createEffect } from '@luna_ui/luna';

const [count, setCount] = createSignal(0);

createEffect(() => {
  console.log('Count is:', count());
});

setCount(1);      // Logs: Count is: 1
setCount(c => c + 1);  // Logs: Count is: 2
```

MoonBitでは：

```moonbit
let count = @signal.signal(0)

@signal.effect(fn() {
  println("Count is: " + count.get().to_string())
})

count.set(1)  // 出力: Count is: 1
count.update(fn(n) { n + 1 })  // 出力: Count is: 2
```

### Islands

Island Architectureにより、部分的なハイドレーションが可能になり、必要な場所にのみJavaScriptを配信します。

- 静的コンテンツは静的なまま
- インタラクティブなコンポーネントは独立してハイドレーション
- 複数のトリガー戦略（load, idle, visible, media）

```html
<div luna:id="counter" luna:client-trigger="visible">
  <button>Count: 0</button>
</div>
```

### Fine-Grained Reactivity

Virtual DOMなし、差分計算なし。Signal単位でDOMを直接更新：

```
Virtual DOM: State → Create Tree → Diff → Patch (O(n))
Luna:        Signal → Direct DOM Update (O(1))
```

## npmパッケージ

```bash
npm install @luna_ui/luna
```

## 機能

| 機能 | 説明 |
|------|------|
| **Signals** | リアクティブプリミティブ (signal, memo, effect) |
| **Islands** | 部分的ハイドレーション |
| **Web Components** | Shadow DOMサポート |
| **SSR** | Declarative Shadow DOMによるサーバーレンダリング |
| **TypeScript** | 完全な型サポート |

## 関連リンク

- [JavaScript チュートリアル](/luna/tutorial-js/) - JavaScript で Luna を学ぶ
- [MoonBit チュートリアル](/luna/tutorial-moonbit/) - MoonBit で Luna を学ぶ
- [API リファレンス (JavaScript)](/luna/api-js/) - JavaScript API
- [API リファレンス (MoonBit)](/luna/api-moonbit/) - MoonBit API
- [Deep Dive](/luna/deep-dive/) - 内部アーキテクチャとパフォーマンス最適化
