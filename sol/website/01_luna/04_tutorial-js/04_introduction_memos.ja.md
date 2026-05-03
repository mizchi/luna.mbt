---
title: "導入: Memos"
---

# Memos（計算値）

Memo は結果をキャッシュし、依存関係が変更されたときのみ再計算する派生値です。

## Memo の作成

```typescript
import { createSignal, createMemo } from '@luna_ui/luna';

const [count, setCount] = createSignal(2);

// count に依存する計算値
const doubled = createMemo(() => count() * 2);

console.log(doubled());  // 4

setCount(5);
console.log(doubled());  // 10
```

## なぜ Memo を使うのか？

### 1. 冗長な計算を避ける

Memo なしでは、高価な計算が毎回実行されます：

```typescript
// 悪い例：filterItems が毎回のレンダリングで実行される
function ItemList() {
  const [items, setItems] = createSignal([...]);
  const [filter, setFilter] = createSignal("");

  return (
    <ul>
      {items().filter(i => i.name.includes(filter())).map(item => (
        <li>{item.name}</li>
      ))}
    </ul>
  );
}

// 良い例：filterItems は items か filter が変更されたときのみ実行
function ItemList() {
  const [items, setItems] = createSignal([...]);
  const [filter, setFilter] = createSignal("");

  const filteredItems = createMemo(() =>
    items().filter(i => i.name.includes(filter()))
  );

  return (
    <ul>
      {filteredItems().map(item => (
        <li>{item.name}</li>
      ))}
    </ul>
  );
}
```

### 2. 計算値を共有

```typescript
const [firstName, setFirstName] = createSignal("John");
const [lastName, setLastName] = createSignal("Doe");

// 共有される計算値
const fullName = createMemo(() => `${firstName()} ${lastName()}`);

// 複数の場所で使用 - 一度だけ計算
<h1>Welcome, {fullName()}</h1>
<p>Logged in as {fullName()}</p>
```

## Memo はキャッシュされる

Memo は依存関係が変更されたときのみ再計算されます：

```typescript
const [count, setCount] = createSignal(0);
const [other, setOther] = createSignal(0);

const expensive = createMemo(() => {
  console.log("Computing...");
  return count() * 2;
});

expensive();  // "Computing..." をログ、0 を返す
expensive();  // ログなし（キャッシュ）、0 を返す

setOther(5);  // 再計算をトリガーしない
expensive();  // ログなし（キャッシュ）、0 を返す

setCount(1);  // 再計算をトリガー
expensive();  // "Computing..." をログ、2 を返す
```

## チェーンされた Memo

Memo は他の Memo に依存できます：

```typescript
const [price, setPrice] = createSignal(100);
const [quantity, setQuantity] = createSignal(2);
const [taxRate, setTaxRate] = createSignal(0.1);

const subtotal = createMemo(() => price() * quantity());
const tax = createMemo(() => subtotal() * taxRate());
const total = createMemo(() => subtotal() + tax());

console.log(total());  // 220

setQuantity(3);
console.log(total());  // 330（影響を受けた Memo のみ再計算）
```

## Memo vs Effect

| 観点 | Memo | Effect |
|------|------|--------|
| 値を返す | はい | いいえ |
| 結果をキャッシュ | はい | いいえ |
| 用途 | 派生データ | 副作用 |
| 遅延評価 | はい（読み取り時に計算） | いいえ（即座に実行） |

```typescript
// 計算値には Memo を使用
const doubled = createMemo(() => count() * 2);

// 副作用には Effect を使用
createEffect(() => {
  document.title = `Count: ${count()}`;
});
```

## 一般的なパターン

### フィルター/ソートされたリスト

```typescript
const [items, setItems] = createSignal([...]);
const [sortBy, setSortBy] = createSignal("name");
const [filterText, setFilterText] = createSignal("");

const displayItems = createMemo(() => {
  return items()
    .filter(i => i.name.includes(filterText()))
    .sort((a, b) => a[sortBy()].localeCompare(b[sortBy()]));
});
```

### バリデーション

```typescript
const [email, setEmail] = createSignal("");
const [password, setPassword] = createSignal("");

const isValid = createMemo(() => {
  const emailOk = email().includes("@");
  const passwordOk = password().length >= 8;
  return emailOk && passwordOk;
});

<button disabled={!isValid()}>送信</button>
```

## 試してみよう

ショッピングカートを作成：

1. `items` Signal（`{name, price, quantity}` の配列）
2. `subtotal` Memo
3. `tax` Memo（10%）
4. `total` Memo

<details>
<summary>解答</summary>

```typescript
const [items, setItems] = createSignal([
  { name: "りんご", price: 100, quantity: 3 },
  { name: "バナナ", price: 50, quantity: 5 },
]);

const subtotal = createMemo(() =>
  items().reduce((sum, item) => sum + item.price * item.quantity, 0)
);

const tax = createMemo(() => subtotal() * 0.1);

const total = createMemo(() => subtotal() + tax());

// 表示
<p>小計: ¥{subtotal()}</p>
<p>税: ¥{tax()}</p>
<p>合計: ¥{total()}</p>
```

</details>

## 次へ

[バッチ更新 →](./reactivity_batch) について学ぶ
