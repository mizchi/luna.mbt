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
///|
using @luna { signal }

// Basic signal
let count = signal(0)

// With initial value
let name = signal("Luna")

// With struct
let user = signal({ name: "Alice", age: 25 })
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
///|
using @luna { signal }
using @element { text_dyn }

let count = signal(5)

println(count.get())  // 5

// In component - creates reactive binding
text_dyn(() => "Count: " + count.get().to_string())
```

## Writing Values

### Direct Set

```typescript
const [count, setCount] = createSignal(0);

setCount(5);        // Set to 5
setCount(10);       // Set to 10
```

```moonbit
///|
using @luna { signal }

let count = signal(0)

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
///|
using @luna { signal }

let count = signal(0)

count.update(n => n + 1)  // Increment
count.update(n => n * 2)  // Double
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
///|
using @luna { signal, effect }

let count = signal(0)
let other = signal(0)

let _ = effect(() => {
  // This effect only re-runs when `other` changes
  println(count.peek().to_string() + ", " + other.get().to_string())
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
///|
using @luna { signal }

let user = signal({ name: "Alice", age: 25 })

// Create new struct with updated field
user.update(u => { ..u, age: 26 })
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
