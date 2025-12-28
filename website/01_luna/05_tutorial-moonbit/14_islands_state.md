---
title: "Islands: State"
---

# Server-to-Client State

Pass data from server (MoonBit) to client (TypeScript) with type safety.

## The Flow

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

## Defining State

### MoonBit (Server)

```moonbit
using @server_dom { island, button, text }
using @luna { Load }

struct CounterState {
  initial : Int
  max : Int
} derive(ToJson, FromJson)

fn counter_island(state : CounterState) -> @luna.Node {
  island(
    id="counter",
    url="/static/counter.js",
    state=state.to_json().stringify(),
    trigger=Load,
    children=[
      button([text("Count: " + state.initial.to_string())])
    ],
  )
}
```

### TypeScript (Client)

```typescript
// counter.ts
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
struct UserCardState {
  user : User
  settings : Settings
} derive(ToJson, FromJson)

struct User {
  id : Int
  name : String
  email : String
} derive(ToJson, FromJson)

struct Settings {
  theme : String
  compact : Bool
} derive(ToJson, FromJson)
```

### Arrays

```moonbit
struct TodoListState {
  todos : Array[Todo]
  filter : String
} derive(ToJson, FromJson)

struct Todo {
  id : Int
  text : String
  done : Bool
} derive(ToJson, FromJson)
```

### Enums (Tagged Unions)

```moonbit
enum Status {
  Loading
  Error(String)
  Success(Int)
} derive(ToJson, FromJson)

// Serializes as:
// Loading -> {"$tag": "Loading"}
// Error("msg") -> {"$tag": "Error", "0": "msg"}
// Success(42) -> {"$tag": "Success", "0": 42}
```

## Security Considerations

### XSS Prevention

Luna automatically escapes state to prevent XSS:

```moonbit
let state = UserState { name: "<script>alert('xss')</script>" }
// Escaped in HTML attribute
```

### Sensitive Data

Never include sensitive data in state:

```moonbit
// BAD - exposed in HTML source
struct BadState {
  api_key : String      // Don't do this!
  password : String     // Never!
} derive(ToJson)

// GOOD - only public data
struct GoodState {
  user_id : Int
  display_name : String
} derive(ToJson)
```

## State Size

Keep state minimal for performance:

```moonbit
// BAD - too much data
struct BadState {
  all_users : Array[User]        // Entire database
  entire_config : Config         // Everything
} derive(ToJson)

// GOOD - only what's needed
struct GoodState {
  current_user_id : Int
  visible_user_ids : Array[Int]  // Just IDs, fetch details client-side
} derive(ToJson)
```

## Type Safety Tips

### Keep Types in Sync

Create matching TypeScript types:

```moonbit
// MoonBit
struct CounterState {
  initial : Int
  max : Int
} derive(ToJson)
```

```typescript
// TypeScript
interface CounterState {
  initial: number;
  max: number;
}
```

### Validate at Runtime (Optional)

```typescript
import { z } from "zod";

const CounterStateSchema = z.object({
  initial: z.number(),
  max: z.number(),
});

function Counter(rawProps: unknown) {
  const props = CounterStateSchema.parse(rawProps);
  // Now props is type-safe
}
```

## Complete Example

### MoonBit

```moonbit
struct ProductIslandState {
  product : Product
  in_cart : Bool
  user_currency : String
} derive(ToJson, FromJson)

struct Product {
  id : Int
  name : String
  price : Int
  stock : Int
} derive(ToJson, FromJson)

fn product_island(state : ProductIslandState) -> @luna.Node {
  island(
    id="product",
    url="/static/product.js",
    state=state.to_json().stringify(),
    trigger=Load,
    children=[
      div([
        h2([text(state.product.name)]),
        p([text(state.user_currency + " " + state.product.price.to_string())]),
      ])
    ],
  )
}
```

### TypeScript

```typescript
interface ProductIslandProps {
  product: {
    id: number;
    name: string;
    price: number;
    stock: number;
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

      <Show when={!inCart()} fallback={<p>In Cart!</p>}>
        <input
          type="number"
          value={quantity()}
          max={props.product.stock}
        />
        <button onClick={addToCart}>Add to Cart</button>
      </Show>
    </div>
  );
}
```

## Try It

Create an island that:
1. Passes a list of products from server
2. Includes user's preferred currency
3. Client can filter and add to cart

## Next

Learn about [Islands Triggers →](./islands_triggers)
