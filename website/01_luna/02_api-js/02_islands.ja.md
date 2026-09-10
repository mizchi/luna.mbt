---
title: Islands & Components API
---

# Islands & Components API

Islands は Web Components による部分ハイドレーションを実現し、制御フローコンポーネントはリアクティブな UI の構築を助けます。

## Hydration API

Luna は、サーバーが `luna:wc-url` / `luna:wc-state` / `luna:wc-trigger` 属性つきで出力したカスタム要素をハイドレートします。Declarative Shadow DOM は任意です。トリガー(`load` / `idle` / `visible` / `media` / `none`)は MoonBit 側と共通です。

### Island モジュールの契約

`luna:wc-url` が指すモジュールは `hydrate` 関数を export しなければなりません(名前付き export でも default でも構いません)。wc-loader がモジュールを動的 import して次のように呼び出します:

```typescript
hydrate(element: Element, state: unknown, name: string): void | (() => void)
```

- `element` — カスタム要素のインスタンス(例: `<wc-counter>` の DOM ノード)
- `state` — `luna:wc-state` をパースした値(JSON)。属性がなければ `{}`
- `name` — 要素のタグ名(例 `"wc-counter"`)
- HMR / 破棄用に、クリーンアップ関数を返すこともできます

```typescript
import { createSignal, render } from '@luna_ui/luna';

interface CounterProps {
  initial: number;
}

export default function hydrate(element: Element, state: CounterProps) {
  const [count, setCount] = createSignal(state.initial);

  render(element, (
    <>
      <style>{`:host { display: block; }`}</style>
      <button onClick={() => setCount(c => c + 1)}>
        Count: {count()}
      </button>
    </>
  ));
}
```

### HTML 属性

```html
<wc-counter
  luna:wc-url="/static/wc-counter.js"
  luna:wc-state='{"initial":5}'
  luna:wc-trigger="load"
>
  <template shadowrootmode="open">
    <button>Count: 5</button>
  </template>
</wc-counter>
```

| 属性 | 説明 |
|------|------|
| `luna:wc-url` | JavaScript モジュールの URL |
| `luna:wc-state` | シリアライズされた props(JSON) |
| `luna:wc-trigger` | ハイドレーションのタイミング |

`customElements.define()` によるカスタム要素の登録は**不要**です。ローダーはタグが登録済みかどうかに関係なく `[luna:wc-url]` を走査します。Declarative Shadow DOM(`<template shadowrootmode="open">`)も任意です。

## ハイドレーショントリガー

| トリガー | HTML 値 | 説明 |
|----------|---------|------|
| Load | `load` | ページ読み込み直後 |
| Idle | `idle` | ブラウザのアイドル時 |
| Visible | `visible` | 要素がビューポートに入ったとき |
| Media | `media:(query)` | メディアクエリが一致したとき |
| None | `none` | 手動トリガーのみ |

### 手動ハイドレーション

```typescript
// 特定のカスタム要素をプログラムからハイドレートする
window.__LUNA_WC_HYDRATE__?.(document.querySelector("my-modal"));
```

## 制御フローコンポーネント

SolidJS 互換の制御フローコンポーネントです。

### For

リストを描画します。

```tsx
import { createSignal, For } from '@luna_ui/luna';

const [items, setItems] = createSignal(['a', 'b', 'c']);

<For each={items}>
  {(item, index) => (
    <div>
      {index()}: {item}
    </div>
  )}
</For>
```

#### シグネチャ

```typescript
interface ForProps<T> {
  each: Accessor<T[]> | T[];
  fallback?: LunaNode;
  children: (item: T, index: Accessor<number>) => LunaNode;
}

function For<T>(props: ForProps<T>): LunaNode;
```

### Index

item をゲッターとして受け取るリスト描画です(参照ではなくインデックスで追跡)。

```tsx
import { createSignal, Index } from '@luna_ui/luna';

const [items, setItems] = createSignal(['a', 'b', 'c']);

<Index each={items}>
  {(itemGetter, index) => (
    <div>
      {index}: {itemGetter()}
    </div>
  )}
</Index>
```

**For との違い:**
- `For` — item が値、index がアクセサ
- `Index` — item がアクセサ(ゲッター)、index が値

### Show

条件付き描画です。

```tsx
import { createSignal, Show } from '@luna_ui/luna';

const [isVisible, setIsVisible] = createSignal(false);

<Show when={isVisible} fallback={<div>Hidden</div>}>
  <div>Visible!</div>
</Show>

// 関数 children — 引数はアクセサなので呼び出す
const [user, setUser] = createSignal<User | null>(null);

<Show when={user}>
  {(u) => <div>Hello, {u().name}</div>}
</Show>
```

#### シグネチャ

```typescript
interface ShowProps<T> {
  when: T | Accessor<T>;
  fallback?: LunaNode;
  children: (() => LunaNode) | ((item: Accessor<NonNullable<T>>) => LunaNode);
}

function Show<T>(props: ShowProps<T>): LunaNode;
```

JSX の children は自動的にサンクに包まれるので、`<Show><div/></Show>` はそのまま書けます。関数を明示的に渡した場合、その引数は `Accessor<NonNullable<T>>` です — `u` ではなく `u()` です。

### Switch / Match

複数条件の描画です。

```tsx
import { createSignal, Switch, Match } from '@luna_ui/luna';

const [state, setState] = createSignal<'loading' | 'ready' | 'error'>('loading');

<Switch fallback={<div>Unknown</div>}>
  <Match when={() => state() === 'loading'}>
    <div>Loading...</div>
  </Match>
  <Match when={() => state() === 'ready'}>
    <div>Ready!</div>
  </Match>
  <Match when={() => state() === 'error'}>
    <div>Error occurred</div>
  </Match>
</Switch>
```

### Portal

children を別の DOM 位置に描画します。

```tsx
import { Portal } from '@luna_ui/luna';

// document.body へ(既定)
<Portal>
  {() => <div class="modal">Modal content</div>}
</Portal>

// セレクタ指定
<Portal mount="#modal-root">
  {() => <div class="modal">Modal content</div>}
</Portal>

// Shadow DOM でカプセル化
<Portal useShadow>
  {() => <div>Encapsulated content</div>}
</Portal>
```

Portal は children を移動するだけで、いつ構築されたかに依存しません。`{<div />}` でも `{() => <div />}` でも動きます。

#### シグネチャ

```typescript
interface PortalProps {
  mount?: Element | string;  // 対象要素または CSS セレクタ
  useShadow?: boolean;       // Shadow DOM を使う
  children: LunaNode | (() => LunaNode);
}

function Portal(props: PortalProps): LunaNode;
```

#### 低レベル API

```typescript
import { portalToBody, portalToSelector, portalWithShadow } from '@luna_ui/luna';

portalToBody([modalContent]);
portalToSelector("#modal-root", [modalContent]);
portalWithShadow([content]);
```

### Provider

子孫に context の値を提供します。

```tsx
import { createContext, useContext, Provider } from '@luna_ui/luna';

const ThemeContext = createContext('light');

<Provider context={ThemeContext} value="dark">
  {() => <App />}
</Provider>

// App や子孫の中で:
const theme = useContext(ThemeContext);  // 'dark'
```

`Provider` の children は**関数**でなければなりません。値がスコープに入っているのはその関数の実行中だけで、素の要素を渡した場合 JSX は `Provider` の呼び出し**前**にそれを評価してしまいます。その中の `useContext()` は外側の値を読み、Provider は何もしていないように見えます。そのため素の要素を渡すと `Provider children must be a function` で失敗します。

```typescript
interface ProviderProps<T> {
  context: Context<T>;
  value: T;
  children: () => LunaNode;
}
```

## DOM ユーティリティ

### mount / render

コンポーネントを DOM 要素にマウントします。

```typescript
import { mount, render, createElement, text } from '@luna_ui/luna';

// どちらも (root, node) を取ります。root が先である点に注意
mount(document.getElementById('app'), <App />);
render(document.getElementById('app'), <App />);

// SolidJS の render と同じ書き方(サンク)も受け付けます
render(document.getElementById('app'), () => <App />);
```

```typescript
function mount(root: Element, node: LunaNode | (() => LunaNode)): void;
function render(root: Element, node: LunaNode | (() => LunaNode)): void;
```

`render` は root を空にしてから描画し、`mount` は既存の内容に追加します。注意が要るのは引数の順序だけです。SolidJS は `render(code, element)`、Luna はその逆です。

### text / textDyn

テキストノードを作ります。

```typescript
import { text, textDyn, createSignal } from '@luna_ui/luna';

// 静的テキスト
const staticText = text("Hello");

// 動的テキスト(リアクティブ)
const [name, setName] = createSignal("Luna");
const dynamicText = textDyn(() => `Hello, ${name()}`);
```

### show

条件付き描画のヘルパーです。

```typescript
import { show, text, createSignal } from '@luna_ui/luna';

const [visible, setVisible] = createSignal(true);

const node = show(
  visible,
  () => text("Visible!")
);
```

### forEach

低レベルのリスト描画です。

```typescript
import { forEach, text, createSignal } from '@luna_ui/luna';

const [items, setItems] = createSignal(['a', 'b', 'c']);

const list = forEach(
  items,
  (item, index) => text(`${index}: ${item}`)
);
```

### イベントハンドラ

JSX ではハンドラを props として渡します:

```tsx
<button onClick={(e) => console.log('clicked')}>Click</button>
<input onInput={(e) => console.log('input')} onKeyDown={(e) => console.log('key')} />
```

`events().click(…)` は MoonBit 専用です。`HandlerMap` のチェーンメソッドは MoonBit の extern で、返されるオブジェクトには結び付きません。JavaScript からは使いようがなかったため、`@luna_ui/luna` からの export を取り下げました。JavaScript では上の JSX props を使ってください。

JavaScript 向けに用意されているのは `event-utils` エントリポイントの読み取りヘルパーです:

```typescript
import { getTargetValue, isEnterKey, stopEvent } from '@luna_ui/luna/event-utils';

<input onKeyDown={(e) => { if (isEnterKey(e)) { stopEvent(e); submit(getTargetValue(e)); } }} />
```

### ホスト要素

`hydrate` の中では、ホスト要素は第 1 引数(`element`)です。`useHost` のような別のヘルパーはありません。`element` を直接操作してください。

```typescript
import { createSignal, render } from '@luna_ui/luna';

export default function hydrate(element: Element) {
  const [count, setCount] = createSignal(0);

  const handleClick = () => {
    setCount(c => c + 1);
    element.dispatchEvent(new CustomEvent('count-changed', {
      detail: { count: count() },
      bubbles: true,
    }));
  };

  render(element, <button onClick={handleClick}>Click ({count()})</button>);
}
```

## 実践的な指針

### 適切なトリガーを選ぶ

| コンテンツ | 推奨トリガー |
|-----------|-------------|
| ファーストビュー、重要 | `load` |
| スクロール先 | `visible` |
| 計測など非重要 | `idle` |
| デスクトップ限定機能 | `media` |
| ユーザー操作起点(モーダル等) | `none` |

### Island の数を抑える

小さい Island を多数置くより、大きめの Island を少数置くほうが有利です:

```
小さい Island 10 個 = スクリプト読み込み 10 回
大きめの Island 2 個 = スクリプト読み込み 2 回
```

### 状態を最小限に

必要なものだけシリアライズします:

```typescript
// 良い — 最小限の状態
interface Props {
  userId: number;
  displayName: string;
}

// 悪い — データが多すぎる
interface Props {
  user: FullUserObject;
  allSettings: CompleteSettings;
}
```

## API まとめ

### ハイドレーション

| Export | 説明 |
|--------|------|
| `export default function hydrate(el, state, name)` | Island モジュールのエントリポイント。ローダーがカスタム要素・パース済み JSON state・タグ名を渡して呼ぶ |
| `render(el, jsx)` | JSX を要素に描画 |

### 制御フロー

| コンポーネント | 説明 |
|---------------|------|
| `For` | 参照ベースのリスト描画 |
| `Index` | インデックスベースのリスト描画 |
| `Show` | 条件付き描画 |
| `Switch` / `Match` | 多分岐の条件描画 |
| `Portal` | 別の位置へ描画 |
| `Provider` | context の値を提供 |

### DOM

| 関数 | 説明 |
|------|------|
| `mount(el, node)` | 要素にマウント |
| `render(el, node)` | 要素に描画 |
| `text(content)` | 静的テキストノード |
| `textDyn(getter)` | 動的テキストノード |
| `show(cond, render)` | 条件付きノード |
| `forEach(items, render)` | ノードのリスト |
| `onClick` / `onInput` / … | JSX props としてハンドラを渡す |
| `@luna_ui/luna/event-utils` | `getTargetValue` / `isEnterKey` / `stopEvent` など |
