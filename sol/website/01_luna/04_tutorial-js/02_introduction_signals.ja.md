---
title: "導入: Signals"
---

# Signals

Signal は値を保持し、変更時にサブスクライバーに通知するリアクティブコンテナです。

## Signal の作成

```typescript
import { createSignal } from '@luna_ui/luna';

// 基本的な Signal
const [count, setCount] = createSignal(0);

// 初期値付き
const [name, setName] = createSignal("Luna");

// 複雑な型
const [user, setUser] = createSignal({ name: "Alice", age: 25 });
```

## 値の読み取り

Signal を関数として呼び出して値を読み取ります：

```typescript
const [count, setCount] = createSignal(5);

console.log(count());  // 5

// JSX 内 - リアクティブバインディングを作成
<p>Count: {count()}</p>
```

## 値の書き込み

### 直接設定

```typescript
const [count, setCount] = createSignal(0);

setCount(5);        // 5 に設定
setCount(10);       // 10 に設定
```

### 関数による更新

前の値に基づいて更新：

```typescript
const [count, setCount] = createSignal(0);

setCount(c => c + 1);  // インクリメント
setCount(c => c * 2);  // 2倍
```

## Peek（追跡なしで読み取り）

依存関係を作成せずに Signal を読み取る：

```typescript
import { createSignal, createEffect } from '@luna_ui/luna';

const [count, setCount] = createSignal(0);
const [other, setOther] = createSignal(0);

createEffect(() => {
  // この Effect は `other` が変更されたときのみ再実行
  // count を読み取っているにもかかわらず
  console.log(count.peek(), other());
});
```

## オブジェクトを持つ Signal

オブジェクトを扱う場合、更新をトリガーするには新しいオブジェクトを作成する必要があります：

```typescript
const [user, setUser] = createSignal({ name: "Alice", age: 25 });

// 間違い - ミューテーションは更新をトリガーしない
user().age = 26;

// 正しい - 新しいオブジェクトを作成
setUser(u => ({ ...u, age: 26 }));
```

## 複数の Signal

Signal は独立しています。一つを変更しても他に影響しません：

```typescript
const [firstName, setFirstName] = createSignal("John");
const [lastName, setLastName] = createSignal("Doe");

// それぞれ独立して更新
<p>First: {firstName()}</p>    {/* firstName 変更時に更新 */}
<p>Last: {lastName()}</p>      {/* lastName 変更時に更新 */}
```

## 試してみよう

2つの入力（姓、名）を持つフォームを作成し、フルネームを表示：

<details>
<summary>解答</summary>

```typescript
function NameForm() {
  const [firstName, setFirstName] = createSignal("");
  const [lastName, setLastName] = createSignal("");

  return (
    <div>
      <input
        value={firstName()}
        onInput={(e) => setFirstName(e.target.value)}
        placeholder="名"
      />
      <input
        value={lastName()}
        onInput={(e) => setLastName(e.target.value)}
        placeholder="姓"
      />
      <p>フルネーム: {firstName()} {lastName()}</p>
    </div>
  );
}
```

</details>

## 次へ

[Effects →](./introduction_effects) について学ぶ
