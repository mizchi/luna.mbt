---
title: "Control Flow: For"
---

# For (List Rendering)

Efficiently render lists with reactive updates.

## Basic Usage

### TypeScript

```typescript
import { createSignal, For } from '@mizchi/luna';

function TodoList() {
  const [todos, setTodos] = createSignal([
    { id: 1, text: "Learn Luna" },
    { id: 2, text: "Build app" },
    { id: 3, text: "Deploy" },
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

### MoonBit

```moonbit
///|
using @element {
  ul, li, text, for_each,
  type DomNode,
}
using @luna { signal }

fn todo_list() -> DomNode {
  let todos = signal([
    { id: 1, text: "Learn Luna" },
    { id: 2, text: "Build app" },
  ])

  ul([
    for_each(
      each=fn() { todos.get() },
      fn(todo) {
        li([text(todo.text)])
      },
    ),
  ])
}
```

## With Index

Access the current index:

```typescript
<For each={items()}>
  {(item, index) => (
    <li>
      {index() + 1}. {item.name}
    </li>
  )}
</For>
```

Note: `index` is a function (signal) because it can change when items are reordered.

## Keyed Lists

For optimal performance, items should have unique keys. Luna uses reference identity by default, but you can provide a key function:

```typescript
<For each={users()} key={(user) => user.id}>
  {(user) => <UserCard user={user} />}
</For>
```

## How For Differs from map()

### Array.map()

```typescript
// Re-creates ALL li elements when any item changes
<ul>
  {todos().map(todo => <li>{todo.text}</li>)}
</ul>
```

### For Component

```typescript
// Only updates changed items
<ul>
  <For each={todos()}>
    {(todo) => <li>{todo.text}</li>}
  </For>
</ul>
```

| Approach | On Add | On Remove | On Reorder |
|----------|--------|-----------|------------|
| `map()` | Recreate all | Recreate all | Recreate all |
| `<For>` | Add one | Remove one | Move DOM |

## Fallback for Empty Lists

```typescript
<For each={items()} fallback={<p>No items yet.</p>}>
  {(item) => <Item data={item} />}
</For>
```

## Updating Lists

### Add Item

```typescript
const [items, setItems] = createSignal([{ id: 1, name: "First" }]);

function addItem() {
  setItems(prev => [
    ...prev,
    { id: Date.now(), name: "New Item" }
  ]);
}
```

### Remove Item

```typescript
function removeItem(id) {
  setItems(prev => prev.filter(item => item.id !== id));
}
```

### Update Item

```typescript
function updateItem(id, newName) {
  setItems(prev =>
    prev.map(item =>
      item.id === id ? { ...item, name: newName } : item
    )
  );
}
```

### Reorder Items

```typescript
function moveUp(index) {
  setItems(prev => {
    if (index === 0) return prev;
    const next = [...prev];
    [next[index - 1], next[index]] = [next[index], next[index - 1]];
    return next;
  });
}
```

## Nested For

```typescript
const [categories, setCategories] = createSignal([
  { name: "Fruits", items: ["Apple", "Banana"] },
  { name: "Vegetables", items: ["Carrot", "Broccoli"] },
]);

<For each={categories()}>
  {(category) => (
    <div>
      <h3>{category.name}</h3>
      <ul>
        <For each={category.items}>
          {(item) => <li>{item}</li>}
        </For>
      </ul>
    </div>
  )}
</For>
```

## Common Patterns

### Filterable List

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

<For each={filtered()} fallback={<p>No matches</p>}>
  {(item) => <Item data={item} />}
</For>
```

### Sortable List

```typescript
const [items, setItems] = createSignal([...]);
const [sortBy, setSortBy] = createSignal("name");

const sorted = createMemo(() =>
  [...items()].sort((a, b) => a[sortBy()].localeCompare(b[sortBy()]))
);

<For each={sorted()}>
  {(item) => <Item data={item} />}
</For>
```

### Selection

```typescript
const [items] = createSignal([...]);
const [selected, setSelected] = createSignal(new Set());

function toggleSelect(id) {
  setSelected(prev => {
    const next = new Set(prev);
    if (next.has(id)) next.delete(id);
    else next.add(id);
    return next;
  });
}

<For each={items()}>
  {(item) => (
    <li
      class={selected().has(item.id) ? "selected" : ""}
      onClick={() => toggleSelect(item.id)}
    >
      {item.name}
    </li>
  )}
</For>
```

## Try It

Create a todo list with:
1. Input to add new todos
2. Click to toggle completion
3. Button to remove completed

<details>
<summary>Solution</summary>

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
      <button onClick={addTodo}>Add</button>

      <ul>
        <For each={todos()} fallback={<p>No todos</p>}>
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

      <button onClick={clearCompleted}>Clear Completed</button>
    </div>
  );
}
```

</details>

## Next

Learn about [Switch →](./flow_switch)
