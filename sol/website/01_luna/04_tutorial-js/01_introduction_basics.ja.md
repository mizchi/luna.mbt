---
title: "導入: 基本"
---

# 基本

Luna へようこそ！最初のリアクティブコンポーネントを作成しましょう。

## クイックスタート

最も速い方法は CLI を使用することです：

```bash
npx @luna_ui/luna new myapp
cd myapp
npm install
npm run dev
```

これにより Vite と TypeScript が設定された新しいプロジェクトが作成されます。

## Luna とは？

Luna は細粒度リアクティブ UI フレームワークです。コンポーネントツリー全体を再レンダリングする Virtual DOM フレームワークとは異なり、Luna は変更が必要な正確な DOM ノードのみを更新します。

```
Virtual DOM:  State → Render → Diff → Patch
Luna:         State → 直接更新
```

## 最初のコンポーネント

シンプルなカウンターです：

```typescript
import { createSignal } from '@luna_ui/luna';

function Counter() {
  // リアクティブな状態を作成
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

## 重要な概念

### 1. Signal が状態を保持

```typescript
const [value, setValue] = createSignal(initialValue);
```

- `value()` - 現在の値を読み取り（getter）
- `setValue(newValue)` - 新しい値を設定（setter）

### 2. 読み取りが依存関係を作成

JSX や Effect 内で `count()` を呼び出すと、Luna はそれを依存関係として追跡します。`count` が変更されると、その特定の部分のみが更新されます。

```typescript
// このテキストノードは count を購読
<p>Count: {count()}</p>
```

### 3. 再レンダリングなし

React とは異なり、コンポーネント関数は**一度だけ**実行されます。リアクティブな部分のみが更新されます：

```typescript
function Counter() {
  console.log("これは一度だけ実行されます！");  // 更新ごとではない

  const [count, setCount] = createSignal(0);

  return <p>Count: {count()}</p>;  // このテキストのみ更新
}
```

## 試してみよう

カウンターを修正して：

1. 「Decrement」ボタンを追加
2. count を 0 にする「Reset」ボタンを追加
3. count が偶数か奇数かを表示

<details>
<summary>解答</summary>

```typescript
function Counter() {
  const [count, setCount] = createSignal(0);

  return (
    <div>
      <p>Count: {count()}</p>
      <p>{count() % 2 === 0 ? "偶数" : "奇数"}</p>
      <button onClick={() => setCount(c => c + 1)}>+</button>
      <button onClick={() => setCount(c => c - 1)}>-</button>
      <button onClick={() => setCount(0)}>リセット</button>
    </div>
  );
}
```

</details>

## 次へ

[Signals →](./introduction_signals) について詳しく学ぶ
