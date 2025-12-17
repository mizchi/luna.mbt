---
title: Signals
---

# Signals

SignalはLunaのリアクティビティシステムの基盤です。値を保持し、自動的に依存関係を追跡します。

## Signalの作成

```typescript
import { createSignal } from '@mizchi/luna';

const [count, setCount] = createSignal(0);

// 値を読み取る
console.log(count());  // 0

// 新しい値をセット
setCount(5);
console.log(count());  // 5

// 前の値に基づいて更新
setCount(c => c + 1);
console.log(count());  // 6
```

## Effect

Effectは依存関係が変更されると自動的に実行されます:

```typescript
import { createSignal, createEffect } from '@mizchi/luna';

const [name, setName] = createSignal("Luna");

createEffect(() => {
  console.log(`Hello, ${name()}!`);
});
// 出力: Hello, Luna!

setName("World");
// 出力: Hello, World!
```

## Memo（算出値）

Memoは算出値をキャッシュします:

```typescript
import { createSignal, createMemo } from '@mizchi/luna';

const [count, setCount] = createSignal(2);
const squared = createMemo(() => count() ** 2);

console.log(squared());  // 4

setCount(3);
console.log(squared());  // 9
```

## バッチ更新

複数の更新をバッチ処理して、冗長なeffect実行を避けます:

```typescript
import { createSignal, batch } from '@mizchi/luna';

const [a, setA] = createSignal(0);
const [b, setB] = createSignal(0);

batch(() => {
  setA(1);
  setB(2);
  // Effectはバッチ完了後に1回だけ実行
});
```

## クリーンアップ

Effect内でクリーンアップ関数を登録:

```typescript
import { createSignal, createEffect, onCleanup } from '@mizchi/luna';

const [active, setActive] = createSignal(true);

createEffect(() => {
  if (active()) {
    const interval = setInterval(() => console.log("tick"), 1000);
    onCleanup(() => clearInterval(interval));
  }
});
```

## MoonBit API

```moonbit
// Signalを作成
let count = @luna.signal(0)

// 値を読み取る
let value = count.get()

// 値をセット
count.set(5)

// 関数で更新
count.update(fn(n) { n + 1 })

// 追跡せずに値を取得
let peeked = count.peek()

// Memoを作成
let doubled = @luna.memo(fn() { count.get() * 2 })

// Effectを作成
let dispose = @luna.effect(fn() {
  println("Count: \{count.get()}")
  @luna.on_cleanup(fn() { println("Cleanup") })
})

// Effectを破棄
dispose()
```

## APIリファレンス

| 関数 | 説明 |
|------|------|
| `createSignal(value)` | リアクティブなSignalを作成 |
| `createEffect(fn)` | 副作用を作成 |
| `createMemo(fn)` | キャッシュされた算出値を作成 |
| `batch(fn)` | 複数の更新をバッチ処理 |
| `untrack(fn)` | 依存関係を追跡せずに実行 |
| `onCleanup(fn)` | Effect内でクリーンアップを登録 |
