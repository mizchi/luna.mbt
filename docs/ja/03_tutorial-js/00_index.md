---
title: チュートリアル (JavaScript)
---

# チュートリアル (JavaScript)

JavaScript/TypeScriptでLuna UIを学びます。

## はじめに

```bash
npm install @mizchi/luna
```

## 基本的な使い方

```typescript
import { createSignal, createEffect, createMemo } from '@mizchi/luna';

// リアクティブなシグナルを作成
const [count, setCount] = createSignal(0);

// 算出値を作成
const doubled = createMemo(() => count() * 2);

// 変更に反応
createEffect(() => {
  console.log(`Count: ${count()}, Doubled: ${doubled()}`);
});

// シグナルを更新
setCount(1);      // Logs: Count: 1, Doubled: 2
setCount(c => c + 1);  // Logs: Count: 2, Doubled: 4
```

## トピック

- [基本](/ja/tutorial-js/basics) - Signal、Effect、Memo
- [コンポーネント](/ja/tutorial-js/components) - UIコンポーネントの構築
- [Islands](/ja/tutorial-js/islands) - 部分的ハイドレーション

## 関連

- [MoonBitチュートリアル](/ja/tutorial-moonbit/) - MoonBit開発者向け
- [APIリファレンス](/ja/api/) - 完全なAPIドキュメント
