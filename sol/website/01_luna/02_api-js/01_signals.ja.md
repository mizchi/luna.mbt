---
title: Signals
---

# Signals

Signals は Luna のリアクティビティシステムの基盤です。

## createSignal

リアクティブな値を作成します。

```typescript
import { createSignal } from '@luna_ui/luna';

const [count, setCount] = createSignal(0);

// 読み取り
console.log(count());  // 0

// 書き込み
setCount(1);
setCount(c => c + 1);
```

## createEffect

Signal の変更に反応する副作用を作成します。

```typescript
import { createSignal, createEffect } from '@luna_ui/luna';

const [count, setCount] = createSignal(0);

createEffect(() => {
  console.log('Count changed:', count());
});

setCount(1);  // Logs: Count changed: 1
```

## createMemo

派生値を計算します。依存する Signal が変更されたときのみ再計算されます。

```typescript
import { createSignal, createMemo } from '@luna_ui/luna';

const [count, setCount] = createSignal(2);
const doubled = createMemo(() => count() * 2);

console.log(doubled());  // 4
setCount(3);
console.log(doubled());  // 6
```

## batch

複数の更新をバッチ処理します。

```typescript
import { createSignal, batch } from '@luna_ui/luna';

const [a, setA] = createSignal(0);
const [b, setB] = createSignal(0);

batch(() => {
  setA(1);
  setB(2);
});
// Effect は1回だけ実行される
```

## untrack

Signal の読み取りを追跡から除外します。

```typescript
import { createSignal, createEffect, untrack } from '@luna_ui/luna';

const [a, setA] = createSignal(0);
const [b, setB] = createSignal(0);

createEffect(() => {
  console.log(a(), untrack(() => b()));
});
// a が変更されたときのみ実行される
```
