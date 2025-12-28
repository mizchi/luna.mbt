---
title: "リアクティビティ: Untrack"
---

# Untrack

依存関係を作成せずに Signal を読み取ります。

## 問題

Signal の値を読み取りたいが、その変更を購読したくない場合があります：

```typescript
const [count, setCount] = createSignal(0);
const [multiplier, setMultiplier] = createSignal(2);

createEffect(() => {
  // この Effect は count か multiplier のどちらかが変更されると実行
  console.log(count() * multiplier());
});
```

`count` の変更にのみ反応したい場合はどうすればよいでしょうか？

## Untrack の使用

```typescript
import { createSignal, createEffect, untrack } from '@luna_ui/luna';

const [count, setCount] = createSignal(0);
const [multiplier, setMultiplier] = createSignal(2);

createEffect(() => {
  // `count` のみ追跡、`multiplier` は追跡しない
  const mult = untrack(() => multiplier());
  console.log(count() * mult);
});

setCount(5);        // Effect 実行: 10
setMultiplier(3);   // Effect 実行されない
setCount(6);        // Effect 実行: 18（現在の multiplier を使用）
```

## Untrack vs Peek

両方とも追跡なしで読み取りますが：

| メソッド | スコープ | ユースケース |
|---------|---------|-------------|
| `peek()` | 単一 Signal | 1つの Signal への素早いアクセス |
| `untrack()` | 任意のコードブロック | 複数操作、関数呼び出し |

```typescript
const [a, setA] = createSignal(1);
const [b, setB] = createSignal(2);

createEffect(() => {
  // peek: 単一 Signal
  const valA = a.peek();

  // untrack: 複数操作
  const sum = untrack(() => a() + b());
});
```

## 一般的なユースケース

### 購読なしのログ

```typescript
const [user, setUser] = createSignal(null);

createEffect(() => {
  const u = user();
  if (u) {
    // 購読せずに他の状態をログ
    untrack(() => {
      console.log("User logged in:", u.name);
      console.log("Current page:", page());
      console.log("Session:", session());
    });
  }
});
```

### 値の比較

```typescript
const [current, setCurrent] = createSignal(0);
const [previous, setPrevious] = createSignal(0);

createEffect(() => {
  const curr = current();

  // 追跡せずに前の値と比較
  const prev = untrack(() => previous());

  if (curr !== prev) {
    console.log(`${prev} から ${curr} に変更`);
    setPrevious(curr);
  }
});
```

## 試してみよう

`count` が変更されたときにログを記録し、現在の `timestamp` Signal 値を含めるが、`count` が変更されたときのみ再実行する Effect を作成：

<details>
<summary>解答</summary>

```typescript
const [count, setCount] = createSignal(0);
const [timestamp, setTimestamp] = createSignal(Date.now());

// 定期的に timestamp を更新
setInterval(() => setTimestamp(Date.now()), 1000);

createEffect(() => {
  const c = count();
  const ts = untrack(() => timestamp());

  console.log(`Count: ${c} at ${new Date(ts).toISOString()}`);
});

// Effect は count が変更されたときのみ実行、毎秒ではない
```

</details>

## 次へ

[ネストした Effects →](./reactivity_nested) について学ぶ
