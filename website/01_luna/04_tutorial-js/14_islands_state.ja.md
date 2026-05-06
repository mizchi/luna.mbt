---
title: "Islands: State"
---

# サーバーからクライアントへの State

型安全性を持ってサーバーからクライアントにデータを渡します。

## 問題

サーバーデータをクライアント JavaScript にどうやって渡しますか？

```
サーバー（MoonBit）            クライアント（TypeScript）
     │                              │
     │  データ付き HTML をレンダリング │
     │ ──────────────────────────>  │
     │                              │
     │      props をどう渡す？       │
     └──────────────────────────────┘
```

## 解決策

Luna は状態を JSON として HTML にシリアライズ：

```html
<div
  luna:id="counter"
  luna:state='{"initial":5,"max":100}'
  luna:url="/static/counter.js"
>
  <!-- SSR コンテンツ -->
</div>
```

## State の定義

### サーバーサイド

サーバーは `luna:state` 属性で状態を JSON としてシリアライズします。MoonBit でのサーバーサイドレンダリングについては、[MoonBit チュートリアル](/ja/luna/tutorial-moonbit/)を参照してください。

### クライアントサイド（TypeScript）

```typescript
// counter.ts
import { createSignal, hydrate } from '@luna_ui/luna';

// マッチする TypeScript インターフェースを定義
interface CounterProps {
  initial: number;
  max: number;
}

function Counter(props: CounterProps) {
  const [count, setCount] = createSignal(props.initial);

  const increment = () => {
    setCount(c => Math.min(c + 1, props.max));
  };

  return (
    <button onClick={increment}>
      Count: {count()} / {props.max}
    </button>
  );
}

hydrate("counter", Counter);
```

## 複雑な State

### ネストしたオブジェクト

```typescript
interface UserCardProps {
  user: {
    id: number;
    name: string;
    email: string;
  };
  settings: {
    theme: string;
    compact: boolean;
  };
}
```

### 配列

```typescript
interface TodoListProps {
  todos: Array<{
    id: number;
    text: string;
    done: boolean;
  }>;
  filter: string;
}
```

## 型安全性のヒント

### 1. 型を同期させる

共有型定義を作成するか生成：

```typescript
// types.ts - MoonBit 構造体と同期を維持
export interface CounterProps {
  initial: number;
  max: number;
}
```

### 2. 欠損/デフォルト値の処理

```typescript
interface Props {
  count?: number;
  label?: string;
}

function Counter(props: Props) {
  const count = props.count ?? 0;
  const label = props.label ?? "Count";

  // ...
}
```

## セキュリティ考慮事項

### 機密データ

状態に機密データを含めないこと：

```typescript
// 悪い例 - HTML ソースに公開される
interface BadProps {
  apiKey: string;      // やめて！
  password: string;    // 絶対だめ！
}

// 良い例 - 公開データのみ
interface GoodProps {
  userId: number;
  displayName: string;
}
```

## 試してみよう

商品ページ Island の状態構造を設計：

<details>
<summary>解答</summary>

```typescript
interface ProductIslandProps {
  product: {
    id: number;
    name: string;
    price: number;
    stock: number;
    imageUrl: string;
  };
  inCart: boolean;
  userCurrency: string;
}

function ProductIsland(props: ProductIslandProps) {
  const [inCart, setInCart] = createSignal(props.inCart);
  const [quantity, setQuantity] = createSignal(1);

  const addToCart = () => {
    setInCart(true);
    // カートに追加する API 呼び出し
  };

  return (
    <div>
      <h2>{props.product.name}</h2>
      <p>{props.userCurrency} {props.product.price}</p>
      <p>在庫: {props.product.stock}</p>

      <Show when={!inCart()} fallback={<p>カートに入っています！</p>}>
        <input
          type="number"
          value={quantity()}
          onChange={(e) => setQuantity(+e.target.value)}
          max={props.product.stock}
        />
        <button onClick={addToCart}>カートに追加</button>
      </Show>
    </div>
  );
}
```

</details>

## 次へ

[Web Components Islands →](./islands_webcomponents) について学ぶ
