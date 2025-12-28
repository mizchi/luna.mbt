---
title: "リアクティビティ: Batch"
---

# バッチ更新

複数の Signal 更新をバッチ処理して、Effect を一度だけトリガーします。

## 問題

バッチなしでは、各 Signal 更新が Effect を即座にトリガーします：

```typescript
const [firstName, setFirstName] = createSignal("John");
const [lastName, setLastName] = createSignal("Doe");

createEffect(() => {
  console.log(`Name: ${firstName()} ${lastName()}`);
});

// 2つの別々の更新 = 2回の Effect 実行
setFirstName("Jane");  // Effect 実行: "Jane Doe"
setLastName("Smith");  // Effect 実行: "Jane Smith"
```

これにより以下が発生する可能性があります：
- 不要な再レンダリング
- 一貫性のない中間状態
- パフォーマンスの問題

## Batch の使用

```typescript
import { createSignal, createEffect, batch } from '@luna_ui/luna';

const [firstName, setFirstName] = createSignal("John");
const [lastName, setLastName] = createSignal("Doe");

createEffect(() => {
  console.log(`Name: ${firstName()} ${lastName()}`);
});

// バッチ = 1回の Effect 実行
batch(() => {
  setFirstName("Jane");
  setLastName("Smith");
});
// Effect は一度だけ実行: "Jane Smith"
```

## Batch を使うタイミング

### 関連する複数の更新

```typescript
const [user, setUser] = createSignal(null);
const [loading, setLoading] = createSignal(true);
const [error, setError] = createSignal(null);

async function fetchUser() {
  setLoading(true);

  try {
    const data = await api.getUser();

    // すべてを一度に更新
    batch(() => {
      setUser(data);
      setLoading(false);
      setError(null);
    });
  } catch (e) {
    batch(() => {
      setUser(null);
      setLoading(false);
      setError(e.message);
    });
  }
}
```

### フォーム更新

```typescript
function resetForm() {
  batch(() => {
    setName("");
    setEmail("");
    setPhone("");
  });
}
```

## Batch は同期的

Batch は同期的に実行され、すべての更新後に戻ります：

```typescript
const [count, setCount] = createSignal(0);

batch(() => {
  setCount(1);
  setCount(2);
  setCount(3);
});

console.log(count());  // 3（batch 直後）
```

## ネストした Batch

ネストした batch はフラット化されます - Effect は最も外側の batch 後に実行：

```typescript
const [a, setA] = createSignal(0);
const [b, setB] = createSignal(0);

createEffect(() => console.log(a(), b()));

batch(() => {
  setA(1);

  batch(() => {
    setB(2);  // まだ外側の batch 内
  });

  setA(3);
});
// Effect は一度だけ実行: 3, 2
```

## よくある間違い

### Batch 内の非同期

Batch は同期コードにのみ影響します：

```typescript
// 間違い: async が batch を壊す
batch(async () => {
  setLoading(true);
  const data = await fetch(...);  // batch はここで終了！
  setData(data);                   // バッチされない
  setLoading(false);               // バッチされない
});

// 正しい: 非同期後に batch
async function load() {
  setLoading(true);
  const data = await fetch(...);

  batch(() => {
    setData(data);
    setLoading(false);
  });
}
```

## 試してみよう

RGB スライダーを持つカラーミキサーを作成し、すべてのスライダーが変更されたときにプレビューを一度だけ更新：

<details>
<summary>解答</summary>

```typescript
const [r, setR] = createSignal(128);
const [g, setG] = createSignal(128);
const [b, setB] = createSignal(128);

const color = createMemo(() => `rgb(${r()}, ${g()}, ${b()})`);

createEffect(() => {
  console.log("Color updated:", color());
});

function setPreset(preset) {
  batch(() => {
    setR(preset.r);
    setG(preset.g);
    setB(preset.b);
  });
}

// 使用
setPreset({ r: 255, g: 0, b: 0 });  // 1回の Effect 実行
```

</details>

## 次へ

[Untrack →](./reactivity_untrack) について学ぶ
