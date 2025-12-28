---
title: "導入: Effects"
---

# Effects

Effect は依存関係が変更されたときに自動的に実行される関数です。

## Effect の作成

```typescript
import { createSignal, createEffect } from '@luna_ui/luna';

const [count, setCount] = createSignal(0);

createEffect(() => {
  console.log("Count is:", count());
});

// ログ: "Count is: 0"

setCount(1);
// ログ: "Count is: 1"

setCount(2);
// ログ: "Count is: 2"
```

## 自動依存関係追跡

Effect は読み取った Signal を自動的に追跡します：

```typescript
const [a, setA] = createSignal(1);
const [b, setB] = createSignal(2);

createEffect(() => {
  console.log("a:", a());  // `a` のみ追跡
});

setA(10);  // Effect 実行
setB(20);  // Effect 実行されない（b は追跡されていない）
```

## 条件付き依存関係

依存関係は実行パスに基づいて動的に追跡されます：

```typescript
const [showDetails, setShowDetails] = createSignal(false);
const [name, setName] = createSignal("Luna");
const [details, setDetails] = createSignal("A UI framework");

createEffect(() => {
  console.log("Name:", name());

  if (showDetails()) {
    console.log("Details:", details());  // showDetails が true のときのみ追跡
  }
});

setDetails("New details");  // Effect 実行されない（現在追跡されていない）

setShowDetails(true);       // Effect 実行、`details` を追跡開始

setDetails("Updated");      // Effect 実行（追跡中）
```

## 副作用

Effect は以下のような副作用に最適です：

### DOM 操作

```typescript
const [title, setTitle] = createSignal("My App");

createEffect(() => {
  document.title = title();  // ドキュメントタイトルをリアクティブに更新
});
```

### ログ

```typescript
const [user, setUser] = createSignal(null);

createEffect(() => {
  if (user()) {
    console.log("User logged in:", user().name);
  }
});
```

### API 呼び出し

```typescript
const [searchTerm, setSearchTerm] = createSignal("");

createEffect(() => {
  const term = searchTerm();
  if (term.length > 2) {
    fetch(`/api/search?q=${term}`)
      .then(res => res.json())
      .then(data => setResults(data));
  }
});
```

## Effect の戻り値

Effect は dispose 関数を返すことができます：

```typescript
const dispose = createEffect(() => {
  console.log("Running");
});

// 後で Effect を停止
dispose();
```

## クリーンアップ（onCleanup）

Effect 内でクリーンアップ関数を登録：

```typescript
import { createSignal, createEffect, onCleanup } from '@luna_ui/luna';

const [count, setCount] = createSignal(0);

createEffect(() => {
  const interval = setInterval(() => {
    console.log("Count:", count());
  }, 1000);

  // Effect が再実行または破棄される前にクリーンアップ実行
  onCleanup(() => {
    clearInterval(interval);
  });
});
```

## 一般的なパターン

### デバウンスされた Effect

```typescript
const [search, setSearch] = createSignal("");

createEffect(() => {
  const term = search();

  const timeout = setTimeout(() => {
    fetchResults(term);
  }, 300);

  onCleanup(() => clearTimeout(timeout));
});
```

### イベントリスナー

```typescript
const [element, setElement] = createSignal(null);

createEffect(() => {
  const el = element();
  if (!el) return;

  const handler = () => console.log("Clicked!");
  el.addEventListener("click", handler);

  onCleanup(() => {
    el.removeEventListener("click", handler);
  });
});
```

## 試してみよう

以下を行う Effect を作成：

1. `count` Signal を追跡
2. 実行中は1秒ごとに count をログ
3. count が変更されたときに適切にクリーンアップ

<details>
<summary>解答</summary>

```typescript
const [count, setCount] = createSignal(0);

createEffect(() => {
  const currentCount = count();

  const interval = setInterval(() => {
    console.log("Current count:", currentCount);
  }, 1000);

  onCleanup(() => {
    console.log("Cleaning up for count:", currentCount);
    clearInterval(interval);
  });
});
```

</details>

## 次へ

[Memos →](./introduction_memos) について学ぶ
