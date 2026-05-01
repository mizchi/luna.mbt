---
title: クイックスタート
---

# クイックスタート

## プロジェクトを作成

### TypeScript/JSX

```bash
npx @luna_ui/luna new myapp
cd myapp && npm install && npm run dev
```

### MoonBit

```bash
npx @luna_ui/luna new myapp --mbt
cd myapp && moon update && npm install && npm run dev
```

## 基本的な使い方

### JavaScript

```typescript
import { createSignal, createEffect } from '@luna_ui/luna';

const [count, setCount] = createSignal(0);

createEffect(() => {
  console.log('Count:', count());
});

setCount(1);  // Logs: Count: 1
```

### MoonBit

```moonbit
let count = @signal.signal(0)

@signal.effect(fn() {
  println("Count: " + count.get().to_string())
})

count.set(1)  // 出力: Count: 1
```

## 次のステップ

- [Signals](/ja/luna/api-js/) - Signal API の詳細
- [チュートリアル (JavaScript)](/luna/tutorial-js/) - ステップバイステップガイド
- [チュートリアル (MoonBit)](/luna/tutorial-moonbit/) - MoonBit 版ガイド
