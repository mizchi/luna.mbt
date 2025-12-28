---
title: "制御フロー: For"
---

# For（リストレンダリング）

リアクティブな更新で効率的にリストをレンダリングします。

## 基本的な使い方

```typescript
import { createSignal, For } from '@luna_ui/luna';

function TodoList() {
  const [todos, setTodos] = createSignal([
    { id: 1, text: "Luna を学ぶ" },
    { id: 2, text: "アプリを作る" },
    { id: 3, text: "デプロイ" },
  ]);

  return (
    <ul>
      <For each={todos()}>
        {(todo) => <li>{todo.text}</li>}
      </For>
    </ul>
  );
}
```

## インデックス付き

現在のインデックスにアクセス：

```typescript
<For each={items()}>
  {(item, index) => (
    <li>
      {index() + 1}. {item.name}
    </li>
  )}
</For>
```

注意：`index` は関数（Signal）です。アイテムが並べ替えられると変更される可能性があるためです。

## For と map() の違い

### Array.map()

```typescript
// いずれかのアイテムが変更されるとすべての li 要素を再作成
<ul>
  {todos().map(todo => <li>{todo.text}</li>)}
</ul>
```

### For コンポーネント

```typescript
// 変更されたアイテムのみ更新
<ul>
  <For each={todos()}>
    {(todo) => <li>{todo.text}</li>}
  </For>
</ul>
```

| アプローチ | 追加時 | 削除時 | 並べ替え時 |
|----------|-------|--------|-----------|
| `map()` | すべて再作成 | すべて再作成 | すべて再作成 |
| `<For>` | 1つ追加 | 1つ削除 | DOM を移動 |

## 空リストのフォールバック

```typescript
<For each={items()} fallback={<p>アイテムがありません。</p>}>
  {(item) => <Item data={item} />}
</For>
```

## リストの更新

### アイテム追加

```typescript
const [items, setItems] = createSignal([{ id: 1, name: "First" }]);

function addItem() {
  setItems(prev => [
    ...prev,
    { id: Date.now(), name: "New Item" }
  ]);
}
```

### アイテム削除

```typescript
function removeItem(id) {
  setItems(prev => prev.filter(item => item.id !== id));
}
```

### アイテム更新

```typescript
function updateItem(id, newName) {
  setItems(prev =>
    prev.map(item =>
      item.id === id ? { ...item, name: newName } : item
    )
  );
}
```

## 一般的なパターン

### フィルター可能なリスト

```typescript
const [items, setItems] = createSignal([...]);
const [filter, setFilter] = createSignal("");

const filtered = createMemo(() =>
  items().filter(i => i.name.includes(filter()))
);

<input
  value={filter()}
  onInput={(e) => setFilter(e.target.value)}
/>

<For each={filtered()} fallback={<p>一致なし</p>}>
  {(item) => <Item data={item} />}
</For>
```

## 試してみよう

以下を持つ Todo リストを作成：
1. 新しい Todo を追加する入力
2. クリックで完了をトグル
3. 完了済みを削除するボタン

<details>
<summary>解答</summary>

```typescript
function TodoApp() {
  const [todos, setTodos] = createSignal([]);
  const [input, setInput] = createSignal("");

  const addTodo = () => {
    if (!input()) return;
    setTodos(prev => [
      ...prev,
      { id: Date.now(), text: input(), done: false }
    ]);
    setInput("");
  };

  const toggleTodo = (id) => {
    setTodos(prev =>
      prev.map(t => t.id === id ? { ...t, done: !t.done } : t)
    );
  };

  const clearCompleted = () => {
    setTodos(prev => prev.filter(t => !t.done));
  };

  return (
    <div>
      <input
        value={input()}
        onInput={(e) => setInput(e.target.value)}
        onKeyPress={(e) => e.key === "Enter" && addTodo()}
      />
      <button onClick={addTodo}>追加</button>

      <ul>
        <For each={todos()} fallback={<p>Todo なし</p>}>
          {(todo) => (
            <li
              style={{ textDecoration: todo.done ? "line-through" : "none" }}
              onClick={() => toggleTodo(todo.id)}
            >
              {todo.text}
            </li>
          )}
        </For>
      </ul>

      <button onClick={clearCompleted}>完了済みをクリア</button>
    </div>
  );
}
```

</details>

## 次へ

[Switch →](./flow_switch) について学ぶ
