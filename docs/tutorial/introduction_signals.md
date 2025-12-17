---
title: "Introduction: Signals"
---

# Signals

Signals are reactive containers that hold values and notify subscribers when changed.

## Creating Signals

### TypeScript

```typescript
import { createSignal } from '@mizchi/luna';

// Basic signal
const [count, setCount] = createSignal(0);

// With initial value
const [name, setName] = createSignal("Luna");

// With complex types
const [user, setUser] = createSignal({ name: "Alice", age: 25 });
```

### MoonBit

```moonbit
// Basic signal
let count = @luna.signal(0)

// With initial value
let name = @luna.signal("Luna")

// With struct
let user = @luna.signal({ name: "Alice", age: 25 })
```

## Reading Values

Call the signal as a function to read its value:

### TypeScript

```typescript
const [count, setCount] = createSignal(5);

console.log(count());  // 5

// In JSX - creates reactive binding
<p>Count: {count()}</p>
```

### MoonBit

```moonbit
let count = @luna.signal(5)

println(count.get())  // 5

// In component - creates reactive binding
@element.text_dyn(fn() { "Count: \{count.get()}" })
```

## Writing Values

### Direct Set

```typescript
const [count, setCount] = createSignal(0);

setCount(5);        // Set to 5
setCount(10);       // Set to 10
```

```moonbit
let count = @luna.signal(0)

count.set(5)        // Set to 5
count.set(10)       // Set to 10
```

### Functional Update

Update based on the previous value:

```typescript
const [count, setCount] = createSignal(0);

setCount(c => c + 1);  // Increment
setCount(c => c * 2);  // Double
```

```moonbit
let count = @luna.signal(0)

count.update(fn(n) { n + 1 })  // Increment
count.update(fn(n) { n * 2 })  // Double
```

## Peek (Read Without Tracking)

Read a signal without creating a dependency:

```typescript
import { createSignal, createEffect } from '@mizchi/luna';

const [count, setCount] = createSignal(0);
const [other, setOther] = createSignal(0);

createEffect(() => {
  // This effect only re-runs when `other` changes
  // even though we're reading `count`
  console.log(count.peek(), other());
});
```

```moonbit
let count = @luna.signal(0)
let other = @luna.signal(0)

@luna.effect(fn() {
  // This effect only re-runs when `other` changes
  println("\{count.peek()}, \{other.get()}")
})
```

## Signals with Objects

When working with objects, you need to create a new object to trigger updates:

```typescript
const [user, setUser] = createSignal({ name: "Alice", age: 25 });

// Wrong - mutating doesn't trigger update
user().age = 26;

// Correct - create new object
setUser(u => ({ ...u, age: 26 }));
```

```moonbit
let user = @luna.signal({ name: "Alice", age: 25 })

// Create new struct with updated field
user.update(fn(u) { { ..u, age: 26 } })
```

## Multiple Signals

Signals are independent. Changing one doesn't affect others:

```typescript
const [firstName, setFirstName] = createSignal("John");
const [lastName, setLastName] = createSignal("Doe");

// Each updates independently
<p>First: {firstName()}</p>    {/* Updates when firstName changes */}
<p>Last: {lastName()}</p>      {/* Updates when lastName changes */}
```

## Try It

Create a form with two inputs (first name, last name) and display the full name:

<details>
<summary>Solution</summary>

```typescript
function NameForm() {
  const [firstName, setFirstName] = createSignal("");
  const [lastName, setLastName] = createSignal("");

  return (
    <div>
      <input
        value={firstName()}
        onInput={(e) => setFirstName(e.target.value)}
        placeholder="First name"
      />
      <input
        value={lastName()}
        onInput={(e) => setLastName(e.target.value)}
        placeholder="Last name"
      />
      <p>Full name: {firstName()} {lastName()}</p>
    </div>
  );
}
```

</details>

## Next

Learn about [Effects →](./introduction_effects)
