---
title: Signals API
---

# Signals API

Signals は Luna のリアクティビティシステムの基盤です。API は SolidJS 互換です。

## createSignal

値を保持するリアクティブな Signal を作ります。

```typescript
import { createSignal } from '@luna_ui/luna';

const [count, setCount] = createSignal(0);

// 読み取り
console.log(count());  // 0

// 書き込み
setCount(5);
console.log(count());  // 5

// 前回値をもとに更新
setCount(c => c + 1);
console.log(count());  // 6
```

### シグネチャ

```typescript
function createSignal<T>(value: T): [Accessor<T>, Setter<T>];

type Accessor<T> = () => T;
type Setter<T> = (value: T | ((prev: T) => T)) => void;
```

## createEffect

依存を自動追跡し、変化したら再実行される副作用を作ります。

```typescript
import { createSignal, createEffect } from '@luna_ui/luna';

const [name, setName] = createSignal("Luna");

createEffect(() => {
  console.log(`Hello, ${name()}!`);
});
// 出力: Hello, Luna!

setName("World");
// 出力: Hello, World!
```

### シグネチャ

```typescript
function createEffect(fn: () => void): () => void;
```

effect を止める dispose 関数を返します。

**`createEffect` は遅延実行です。** 本体が最初に走るのは呼び出し地点ではなくマイクロタスクなので、上の出力は現在のタスクが終わったあとに現れます。テストではマイクロタスクを待ってからアサートしてください:

```typescript
createEffect(() => { console.log(name()); });
await new Promise(r => setTimeout(r, 0));   // ここで実行済みになる
```

同期版は `createRenderEffect` です。即座に実行され、以降も依存が変わるたびに実行されます。Luna 自身のプリミティブ(`Show` / `For`)はこちらを使っています。アプリケーションコードでは `createEffect` を既定にしてください。

## createMemo

依存が変わったときだけ再計算される、キャッシュ付きの派生値を作ります。

```typescript
import { createSignal, createMemo } from '@luna_ui/luna';

const [count, setCount] = createSignal(2);
const squared = createMemo(() => count() ** 2);

console.log(squared());  // 4

setCount(3);
console.log(squared());  // 9
```

### シグネチャ

```typescript
function createMemo<T>(fn: () => T): Accessor<T>;
```

## batch

複数の Signal 更新をまとめ、effect の余計な再実行を防ぎます。

```typescript
import { createSignal, createEffect, batch } from '@luna_ui/luna';

const [a, setA] = createSignal(0);
const [b, setB] = createSignal(0);

createEffect(() => {
  console.log(`a=${a()}, b=${b()}`);
});
// 出力: a=0, b=0

batch(() => {
  setA(1);
  setB(2);
  // batch 中は effect が走らない
});
// 出力: a=1, b=2(1 回だけ)
```

## untrack

依存を作らずに Signal を読みます。

```typescript
import { createSignal, createEffect, untrack } from '@luna_ui/luna';

const [a, setA] = createSignal(0);
const [b, setB] = createSignal(0);

createEffect(() => {
  // 'a' だけを追跡し、'b' は追跡しない
  console.log(a(), untrack(() => b()));
});

setA(1);  // effect が再実行される
setB(1);  // effect は再実行されない
```

## onCleanup

effect が再実行される直前、または破棄されたときに走るクリーンアップを登録します。

```typescript
import { createSignal, createEffect, onCleanup } from '@luna_ui/luna';

const [active, setActive] = createSignal(true);

createEffect(() => {
  if (active()) {
    const interval = setInterval(() => console.log("tick"), 1000);
    onCleanup(() => clearInterval(interval));
  }
});
```

## onMount

依存を追跡せずに 1 回だけ実行します(マウントのライフサイクル相当)。

```typescript
import { createSignal, onMount } from '@luna_ui/luna';

const [count, setCount] = createSignal(0);

onMount(() => {
  console.log(count());  // 依存にならない
  console.log("Mounted!");
});

setCount(1);  // onMount は再実行されない
```

## on

依存を明示的に指定するヘルパーです(SolidJS スタイル)。

```typescript
import { createSignal, createEffect, on } from '@luna_ui/luna';

const [count, setCount] = createSignal(0);

// 単一の依存
createEffect(on(count, (value, prev) => {
  console.log(`Changed from ${prev} to ${value}`);
}));

// 複数の依存
const [a, setA] = createSignal(1);
const [b, setB] = createSignal(2);

createEffect(on([a, b], ([aVal, bVal], prev) => {
  console.log(`a=${aVal}, b=${bVal}`);
}));

// defer オプション — 初回実行をスキップする
createEffect(on(count, (value) => {
  console.log(`Count changed to ${value}`);
}, { defer: true }));  // 生成時には走らない
```

初回のコールバックでは `prev` が `null` です。

### シグネチャ

```typescript
function on<T, U>(
  deps: Accessor<T>,
  fn: (input: T, prevInput: T | undefined) => U,
  options?: { defer?: boolean }
): () => U | undefined;

// 複数の依存
function on<T extends readonly Accessor<any>[], U>(
  deps: T,
  fn: (input: [...], prevInput: [...] | undefined) => U,
  options?: { defer?: boolean }
): () => U | undefined;
```

## createRoot

ネストした effect をまとめて破棄できるリアクティブスコープを作ります。

```typescript
import { createSignal, createEffect, createRoot } from '@luna_ui/luna';

const [count, setCount] = createSignal(0);

createRoot((dispose) => {
  createEffect(() => {
    console.log(`Count: ${count()}`);
  });

  setCount(1);  // effect が走る
  dispose();    // 内側の effect をすべて破棄
});

setCount(2);  // effect は走らない
```

## オーナーのユーティリティ

```typescript
import { createRoot, getOwner, runWithOwner, hasOwner } from '@luna_ui/luna';

// オーナースコープの内側かどうか
console.log(hasOwner());  // createRoot の外では false

createRoot(() => {
  console.log(hasOwner());  // 内側では true

  const owner = getOwner();

  // 保存したオーナーの下で後から実行する
  setTimeout(() => {
    runWithOwner(owner, () => {
      // オーナーのリアクティブコンテキストにアクセスできる
    });
  }, 1000);
});
```

## Context API

コンポーネントツリーを通して値を渡します。

```typescript
import { createContext, useContext, provide, Provider } from '@luna_ui/luna';

// 既定値付きで context を作る
const ThemeContext = createContext('light');

// context の値を読む
const theme = useContext(ThemeContext);  // 'light'

// 関数スコープで値を提供する
const result = provide(ThemeContext, 'dark', () => {
  return useContext(ThemeContext);  // 'dark'
});

// Provider コンポーネントでも提供できる(children は関数)
<Provider context={ThemeContext} value="dark">
  {() => <App />}
</Provider>
```

`Provider` の children は関数でなければなりません。JSX は素の `<App />` を `Provider`
の呼び出し**前**に評価してしまうので、その中の `useContext()` は外側の値を読み、Provider
は何もしていないように見えます。そのため素の要素を渡すと、黙って壊れるのではなく
`Provider children must be a function` で失敗します。コンポーネントの完全なシグネチャは
[Provider](./islands#provider) を参照してください。

## Resource API

loading / error 状態つきで非同期処理を扱います。

```typescript
import { createResource, createDeferred } from '@luna_ui/luna';

// fetcher から Resource を作る
const [data, { refetch }] = createResource((resolve, reject) => {
  fetch('/api/data')
    .then(r => r.json())
    .then(resolve)
    .catch(e => reject(e.message));
});

// アクセス
data();         // 値または undefined  (追跡される)
data.loading;   // boolean             (追跡されない)
data.error;     // string または undefined
data.state;     // 'unresolved' | 'pending' | 'ready' | 'errored'
data.latest;    // 最後に確定した値(refetch 中も保持される)
data.pending;   // Accessor<boolean>   (追跡される — effect の中ではこちら)

// 再取得
refetch();

// deferred による手動制御
const [resource, resolve, reject] = createDeferred<number>();
resource.state;   // 'pending'
resolve(42);
resource.state;   // 'ready'、resource() === 42
// あるいは:
reject("Failed!");
```

`loading` と `state` は素の getter で、依存を登録**しません**。effect の中では `data()` か `data.pending` を使ってください:

```typescript
createEffect(() => {
  if (data.pending()) console.log("loading…");
  else console.log(data());
});
```

`createResource` と `createDeferred` はどちらも同じ形のアクセサを返します:

| メンバ | 型 | 追跡 |
|--------|----|------|
| `data()` | `T \| undefined` | する |
| `data.pending` | `Accessor<boolean>` | する |
| `data.loading` | `boolean` | しない |
| `data.error` | `string \| undefined` | しない |
| `data.state` | `'unresolved' \| 'pending' \| 'ready' \| 'errored'` | しない |
| `data.latest` | `T \| undefined` | しない |

## Store API

ネストしたプロパティを追跡できるリアクティブなストアを作ります。

```typescript
import { createStore, produce, reconcile } from '@luna_ui/luna';

const [state, setState] = createStore({
  count: 0,
  user: { name: "John", age: 30 }
});

// 読み取り(リアクティブ)
state.count;
state.user.name;

// パス指定で更新
setState("count", 1);
setState("user", "name", "Jane");

// 関数で更新
setState("count", c => c + 1);

// パスにオブジェクトをマージ
setState("user", { name: "Jane", age: 25 });

// produce による Immer 風のミューテーション
setState("user", produce(user => {
  user.name = "Alice";
  user.age = 28;
}));

// reconcile で値ごと置き換え
setState("items", reconcile(newItems));
```

## ユーティリティ関数

### mergeProps

複数の props オブジェクトをマージします。

```typescript
import { mergeProps } from '@luna_ui/luna';

const defaults = { color: 'blue', size: 'medium' };
const props = { color: 'red' };

const merged = mergeProps(defaults, props);
// { color: 'red', size: 'medium' }

// イベントハンドラはマージされる(両方走る)
const a = { onClick: () => console.log('a') };
const b = { onClick: () => console.log('b') };
mergeProps(a, b).onClick();  // 出力: 'a', 'b'

// class は連結される
mergeProps({ class: 'foo' }, { class: 'bar' });
// { class: 'foo bar' }
```

### splitProps

props をグループに分割します。

```typescript
import { splitProps } from '@luna_ui/luna';

const props = { a: 1, b: 2, c: 3, d: 4 };

const [local, others] = splitProps(props, ['a', 'b']);
// local = { a: 1, b: 2 }
// others = { c: 3, d: 4 }

// 複数グループ
const [group1, group2, rest] = splitProps(props, ['a'], ['b', 'c']);
// group1 = { a: 1 }
// group2 = { b: 2, c: 3 }
// rest = { d: 4 }
```

## API まとめ

### コアのリアクティビティ

| 関数 | 説明 |
|------|------|
| `createSignal(value)` | リアクティブな Signal を作成 |
| `createEffect(fn)` | 副作用を作成(マイクロタスクへ遅延) |
| `createRenderEffect(fn)` | 同期実行の副作用を作成 |
| `createMemo(fn)` | キャッシュ付き派生値を作成 |
| `batch(fn)` | 更新をまとめる |
| `untrack(fn)` | 追跡せずに実行 |
| `onCleanup(fn)` | effect のクリーンアップを登録 |
| `onMount(fn)` | 追跡せずに 1 回実行 |
| `on(deps, fn, opts)` | 依存を明示的に指定 |

### スコープ管理

| 関数 | 説明 |
|------|------|
| `createRoot(fn)` | リアクティブスコープを作成 |
| `getOwner()` | 現在のオーナーを取得 |
| `runWithOwner(owner, fn)` | オーナーの下で実行 |
| `hasOwner()` | オーナーの有無 |

### Context

| 関数 | 説明 |
|------|------|
| `createContext(default)` | context を作成 |
| `useContext(ctx)` | context の値を取得 |
| `provide(ctx, value, fn)` | スコープ内で context を提供 |

### 非同期

| 関数 | 説明 |
|------|------|
| `createResource(fetcher)` | 非同期 Resource を作成 |
| `createDeferred()` | 手動制御の Resource を作成 |

### Store

| 関数 | 説明 |
|------|------|
| `createStore(value)` | リアクティブなストアを作成 |
| `produce(fn)` | Immer 風のミューテーション |
| `reconcile(value)` | 値ごと置き換え |

### ユーティリティ

| 関数 | 説明 |
|------|------|
| `mergeProps(...sources)` | props をマージ |
| `splitProps(props, keys...)` | props をグループに分割 |
