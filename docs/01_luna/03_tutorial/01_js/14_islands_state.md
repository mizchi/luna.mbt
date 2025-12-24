---
title: "Islands: State"
---

# Server-to-Client State

Pass data from server to client with type safety.

## The Problem

How do you pass server data to client JavaScript?

```
Server (MoonBit)              Client (TypeScript)
     │                              │
     │  Render HTML with data       │
     │ ──────────────────────────>  │
     │                              │
     │      How to pass props?      │
     └──────────────────────────────┘
```

## The Solution

Luna serializes state as JSON in the HTML:

```html
<div
  luna:id="counter"
  luna:state='{"initial":5,"max":100}'
  luna:url="/static/counter.js"
>
  <!-- SSR content -->
</div>
```

## Defining State

### Server Side

The server serializes state as JSON in the `luna:state` attribute. For server-side rendering with MoonBit, see the [MoonBit Tutorial](/moonbit/tutorial/).

### Client Side (TypeScript)

```typescript
// counter.ts
import { createSignal, hydrate } from '@luna_ui/luna';

// Define matching TypeScript interface
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

## Complex State

### Nested Objects

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

### Arrays

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

## State Flow

```
┌─────────────────────────────────────────────────┐
│                     Server                       │
├─────────────────────────────────────────────────┤
│  MoonBit Struct                                 │
│  ↓                                              │
│  derive(ToJson)                                 │
│  ↓                                              │
│  .to_json().stringify()                         │
│  ↓                                              │
│  HTML: luna:state='{"initial":5}'               │
└─────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────┐
│                     Client                       │
├─────────────────────────────────────────────────┤
│  Luna Loader                                    │
│  ↓                                              │
│  JSON.parse(luna:state)                         │
│  ↓                                              │
│  TypeScript Interface                           │
│  ↓                                              │
│  Component props                                │
└─────────────────────────────────────────────────┘
```

## Type Safety Tips

### 1. Keep Types in Sync

Create shared type definitions or generate them:

```typescript
// types.ts - Keep in sync with MoonBit structs
export interface CounterProps {
  initial: number;
  max: number;
}

export interface UserProps {
  id: number;
  name: string;
  role: "admin" | "user" | "guest";
}
```

### 2. Validate at Runtime

For extra safety, validate incoming props:

```typescript
import { z } from "zod";

const CounterPropsSchema = z.object({
  initial: z.number(),
  max: z.number(),
});

function Counter(rawProps: unknown) {
  const props = CounterPropsSchema.parse(rawProps);
  // Now props is type-safe
}
```

### 3. Handle Missing/Default Values

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

## Security Considerations

### XSS Prevention

Luna automatically escapes state to prevent XSS. The `luna:state` attribute is safely encoded.

### Sensitive Data

Never include sensitive data in state:

```typescript
// BAD - exposed in HTML source
interface BadProps {
  apiKey: string;      // Don't do this!
  password: string;    // Never!
}

// GOOD - only public data
interface GoodProps {
  userId: number;
  displayName: string;
}
```

## State Size

Keep state minimal for performance:

```typescript
// BAD - too much data
interface BadProps {
  allUsers: User[];        // Entire database
  entireConfig: Config;    // Everything
}

// GOOD - only what's needed
interface GoodProps {
  currentUserId: number;
  visibleUserIds: number[];   // Just IDs, fetch details client-side
}
```

## Try It

Design the state structure for a product page island:

<details>
<summary>Solution</summary>

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
    // API call to add to cart
  };

  return (
    <div>
      <h2>{props.product.name}</h2>
      <p>{props.userCurrency} {props.product.price}</p>
      <p>In stock: {props.product.stock}</p>

      <Show when={!inCart()} fallback={<p>In Cart!</p>}>
        <input
          type="number"
          value={quantity()}
          onChange={(e) => setQuantity(+e.target.value)}
          max={props.product.stock}
        />
        <button onClick={addToCart}>Add to Cart</button>
      </Show>
    </div>
  );
}
```

</details>

## Next

Learn about [Web Components Islands →](./islands_webcomponents)
