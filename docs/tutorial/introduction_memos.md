---
title: "Introduction: Memos"
---

# Memos (Computed Values)

Memos are derived values that cache their result and only recompute when dependencies change.

## Creating Memos

### TypeScript

```typescript
import { createSignal, createMemo } from '@mizchi/luna';

const [count, setCount] = createSignal(2);

// Computed value that depends on count
const doubled = createMemo(() => count() * 2);

console.log(doubled());  // 4

setCount(5);
console.log(doubled());  // 10
```

### MoonBit

```moonbit
let count = @luna.signal(2)

// Computed value that depends on count
let doubled = @luna.memo(fn() { count.get() * 2 })

println(doubled.get())  // 4

count.set(5)
println(doubled.get())  // 10
```

## Why Use Memos?

### 1. Avoid Redundant Computation

Without memo, expensive calculations run every time:

```typescript
// Bad: filterItems runs on every render
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

// Good: filterItems only runs when items or filter change
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

### 2. Share Computed Values

```typescript
const [firstName, setFirstName] = createSignal("John");
const [lastName, setLastName] = createSignal("Doe");

// Shared computed value
const fullName = createMemo(() => `${firstName()} ${lastName()}`);

// Used in multiple places - computed once
<h1>Welcome, {fullName()}</h1>
<p>Logged in as {fullName()}</p>
```

## Memos Are Cached

Memos only recompute when their dependencies change:

```typescript
const [count, setCount] = createSignal(0);
const [other, setOther] = createSignal(0);

const expensive = createMemo(() => {
  console.log("Computing...");
  return count() * 2;
});

expensive();  // Logs "Computing...", returns 0
expensive();  // No log (cached), returns 0

setOther(5);  // Does NOT trigger recomputation
expensive();  // No log (cached), returns 0

setCount(1);  // Triggers recomputation
expensive();  // Logs "Computing...", returns 2
```

## Chained Memos

Memos can depend on other memos:

```typescript
const [price, setPrice] = createSignal(100);
const [quantity, setQuantity] = createSignal(2);
const [taxRate, setTaxRate] = createSignal(0.1);

const subtotal = createMemo(() => price() * quantity());
const tax = createMemo(() => subtotal() * taxRate());
const total = createMemo(() => subtotal() + tax());

console.log(total());  // 220

setQuantity(3);
console.log(total());  // 330 (only affected memos recompute)
```

```moonbit
let price = @luna.signal(100)
let quantity = @luna.signal(2)
let tax_rate = @luna.signal(0.1)

let subtotal = @luna.memo(fn() { price.get() * quantity.get() })
let tax = @luna.memo(fn() { subtotal.get() * tax_rate.get() })
let total = @luna.memo(fn() { subtotal.get() + tax.get() })

println(total.get())  // 220.0
```

## Memo vs Effect

| Aspect | Memo | Effect |
|--------|------|--------|
| Returns value | Yes | No |
| Caches result | Yes | No |
| For | Derived data | Side effects |
| Lazy | Yes (computed on read) | No (runs immediately) |

```typescript
// Use Memo for computed values
const doubled = createMemo(() => count() * 2);

// Use Effect for side effects
createEffect(() => {
  document.title = `Count: ${count()}`;
});
```

## Common Patterns

### Filtered/Sorted Lists

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

### Validation

```typescript
const [email, setEmail] = createSignal("");
const [password, setPassword] = createSignal("");

const isValid = createMemo(() => {
  const emailOk = email().includes("@");
  const passwordOk = password().length >= 8;
  return emailOk && passwordOk;
});

<button disabled={!isValid()}>Submit</button>
```

### Conditional Logic

```typescript
const [user, setUser] = createSignal(null);

const greeting = createMemo(() => {
  const u = user();
  if (!u) return "Please log in";
  if (u.isAdmin) return `Welcome, Admin ${u.name}`;
  return `Hello, ${u.name}`;
});
```

## Try It

Create a shopping cart with:

1. An `items` signal (array of `{name, price, quantity}`)
2. A `subtotal` memo
3. A `tax` memo (10%)
4. A `total` memo

<details>
<summary>Solution</summary>

```typescript
const [items, setItems] = createSignal([
  { name: "Apple", price: 1.00, quantity: 3 },
  { name: "Banana", price: 0.50, quantity: 5 },
]);

const subtotal = createMemo(() =>
  items().reduce((sum, item) => sum + item.price * item.quantity, 0)
);

const tax = createMemo(() => subtotal() * 0.1);

const total = createMemo(() => subtotal() + tax());

// Display
<p>Subtotal: ${subtotal().toFixed(2)}</p>
<p>Tax: ${tax().toFixed(2)}</p>
<p>Total: ${total().toFixed(2)}</p>
```

</details>

## Next

Learn about [Batch Updates →](./reactivity_batch)
