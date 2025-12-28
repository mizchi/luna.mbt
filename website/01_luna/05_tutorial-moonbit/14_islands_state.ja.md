---
title: "Islands: State"
---

# クライアントへの State 渡し

サーバーからクライアントにデータを渡します。

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

Luna は状態を JSON として HTML にシリアライズ。

### サーバーサイド（MoonBit）

```moonbit
struct CounterState {
  initial : Int
  max : Int
} derive(ToJson)

fn counter_island(state : CounterState) -> @luna.Node {
  island(
    id="counter",
    url="/static/counter.js",
    state=state.to_json().stringify(),
    trigger=Load,
    children=[
      div([
        button([text("Count: " + state.initial.to_string())])
      ])
    ],
  )
}
```

### クライアントサイド（TypeScript）

```typescript
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

### ネストした構造体

```moonbit
struct UserCardState {
  user : User
  settings : Settings
} derive(ToJson)

struct User {
  id : Int
  name : String
  email : String
} derive(ToJson)

struct Settings {
  theme : String
  compact : Bool
} derive(ToJson)
```

### 配列

```moonbit
struct TodoListState {
  todos : Array[Todo]
  filter : String
} derive(ToJson)

struct Todo {
  id : Int
  text : String
  done : Bool
} derive(ToJson)
```

## セキュリティ考慮事項

状態に機密データを含めないこと：

```moonbit
// 悪い例 - HTML ソースに公開される
struct BadState {
  api_key : String    // やめて！
  password : String   // 絶対だめ！
}

// 良い例 - 公開データのみ
struct GoodState {
  user_id : Int
  display_name : String
}
```

## 試してみよう

商品ページ Island の状態構造を設計

## 次へ

[Islands Triggers →](./islands_triggers) について学ぶ
