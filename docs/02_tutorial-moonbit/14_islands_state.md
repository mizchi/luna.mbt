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

### Server Side (MoonBit)

```moonbit
///|
using @server_dom { island, button, text, type Node }
using @luna { Load }

// Define a struct for your props
pub struct CounterProps {
  initial : Int
  max : Int
} derive(ToJson, FromJson)

fn counter_island(props : CounterProps) -> Node {
  island(
    id="counter",
    url="/static/counter.js",
    state=props.to_json().stringify(),  // Serialize to JSON
    trigger=Load,
    children=[
      button([text("Count: \{props.initial}")])
    ],
  )
}

// Usage
counter_island({ initial: 5, max: 100 })
```

### Client Side (TypeScript)

```typescript
// counter.ts
import { createSignal, hydrate } from '@mizchi/luna';

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

```moonbit
pub struct UserCardProps {
  user : User
  settings : Settings
} derive(ToJson, FromJson)

pub struct User {
  id : Int
  name : String
  email : String
} derive(ToJson, FromJson)

pub struct Settings {
  theme : String
  compact : Bool
} derive(ToJson, FromJson)
```

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

```moonbit
pub struct TodoListProps {
  todos : Array[Todo]
  filter : String
} derive(ToJson, FromJson)

pub struct Todo {
  id : Int
  text : String
  done : Bool
} derive(ToJson, FromJson)
```

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

Luna automatically escapes state to prevent XSS:

```moonbit
// This is safe - Luna escapes the JSON
let user_input = "<script>alert('xss')</script>"
@server_dom.island(
  state=user_input.to_json().stringify(),  // Escaped
  ...
)
```

### Sensitive Data

Never include sensitive data in state:

```moonbit
// BAD - exposed in HTML source
pub struct BadProps {
  api_key : String      // Don't do this!
  password : String     // Never!
}

// GOOD - only public data
pub struct GoodProps {
  user_id : Int
  display_name : String
}
```

## State Size

Keep state minimal for performance:

```moonbit
// BAD - too much data
pub struct BadProps {
  all_users : Array[User]        // Entire database
  entire_config : Config          // Everything
}

// GOOD - only what's needed
pub struct GoodProps {
  current_user_id : Int
  visible_users : Array[Int]      // Just IDs, fetch details client-side
}
```

## Try It

Design the state structure for a product page island:

<details>
<summary>Solution</summary>

**MoonBit:**

```moonbit
pub struct ProductIslandProps {
  product : ProductSummary
  in_cart : Bool
  user_currency : String
} derive(ToJson, FromJson)

pub struct ProductSummary {
  id : Int
  name : String
  price : Double
  stock : Int
  image_url : String
} derive(ToJson, FromJson)
```

**TypeScript:**

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
