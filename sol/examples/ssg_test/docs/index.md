---
title: Shiki Syntax Highlighting Test
description: Test syntax highlighting for various languages
layout: doc
---

# Syntax Highlighting Test

This page tests Shiki syntax highlighting for various programming languages.

## JSON

```json
{
  "name": "luna-framework",
  "version": "0.1.0",
  "dependencies": {
    "shiki": "^1.0.0"
  },
  "scripts": {
    "build": "moon build",
    "test": "moon test"
  }
}
```

## HTML

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Luna App</title>
  <link rel="stylesheet" href="/style.css">
</head>
<body>
  <div id="app">
    <h1>Hello, Luna!</h1>
    <button onclick="handleClick()">Click me</button>
  </div>
  <script type="module" src="/main.js"></script>
</body>
</html>
```

## CSS

```css
:root {
  --primary-color: #3451b2;
  --text-color: #213547;
  --bg-color: #ffffff;
}

.container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 2rem;
}

.button {
  background: var(--primary-color);
  color: white;
  border: none;
  padding: 0.5rem 1rem;
  border-radius: 4px;
  cursor: pointer;
  transition: opacity 0.2s;
}

.button:hover {
  opacity: 0.9;
}

@media (prefers-color-scheme: dark) {
  :root {
    --text-color: #e5e7eb;
    --bg-color: #1a1a1a;
  }
}
```

## JavaScript

```javascript
// Signal implementation
function createSignal(initialValue) {
  let value = initialValue;
  const subscribers = new Set();

  const get = () => value;

  const set = (newValue) => {
    if (value !== newValue) {
      value = newValue;
      subscribers.forEach(fn => fn(value));
    }
  };

  const subscribe = (fn) => {
    subscribers.add(fn);
    return () => subscribers.delete(fn);
  };

  return { get, set, subscribe };
}

// Usage
const count = createSignal(0);
count.subscribe(v => console.log('Count:', v));
count.set(count.get() + 1);
```

## TypeScript

```typescript
// Type-safe signal implementation
interface Signal<T> {
  get(): T;
  set(value: T): void;
  subscribe(fn: (value: T) => void): () => void;
}

function createSignal<T>(initialValue: T): Signal<T> {
  let value = initialValue;
  const subscribers = new Set<(value: T) => void>();

  return {
    get: () => value,
    set: (newValue: T) => {
      if (value !== newValue) {
        value = newValue;
        subscribers.forEach(fn => fn(value));
      }
    },
    subscribe: (fn: (value: T) => void) => {
      subscribers.add(fn);
      return () => subscribers.delete(fn);
    }
  };
}

// Generic component props
interface ComponentProps<T> {
  data: T;
  onUpdate?: (value: T) => void;
}

// Usage with type inference
const counter = createSignal<number>(0);
const name = createSignal<string>('Luna');
```

## Rust

```rust
// MoonBit-like syntax (using Rust highlighting)
pub struct Signal<T> {
    value: T,
    subscribers: Vec<Box<dyn Fn(&T)>>,
}

impl<T: Clone + PartialEq> Signal<T> {
    pub fn new(initial: T) -> Self {
        Signal {
            value: initial,
            subscribers: Vec::new(),
        }
    }

    pub fn get(&self) -> &T {
        &self.value
    }

    pub fn set(&mut self, new_value: T) {
        if self.value != new_value {
            self.value = new_value;
            for subscriber in &self.subscribers {
                subscriber(&self.value);
            }
        }
    }

    pub fn subscribe<F>(&mut self, f: F)
    where
        F: Fn(&T) + 'static,
    {
        self.subscribers.push(Box::new(f));
    }
}

fn main() {
    let mut count = Signal::new(0);
    count.subscribe(|v| println!("Count: {}", v));
    count.set(1);
}
```

## MoonBit

```mbt
///| Signal implementation in MoonBit
pub struct Signal[T] {
  mut value : T
  subscribers : Array[(T) -> Unit]
}

pub fn[T] Signal::new(initial : T) -> Signal[T] {
  { value: initial, subscribers: [] }
}

pub fn[T] get(self : Signal[T]) -> T {
  self.value
}

pub fn[T : Eq] set(self : Signal[T], new_value : T) -> Unit {
  if self.value != new_value {
    self.value = new_value
    for subscriber in self.subscribers {
      subscriber(self.value)
    }
  }
}

pub fn[T] subscribe(self : Signal[T], f : (T) -> Unit) -> Unit {
  self.subscribers.push(f)
}

fn main {
  let count = Signal::new(0)
  count.subscribe(fn(v) { println("Count: \{v}") })
  count.set(1)
}
```

## Code with Filename

```js:src/utils/signal.js
// Signal utility module
export function createSignal(initial) {
  let value = initial;
  return {
    get: () => value,
    set: (v) => { value = v; }
  };
}
```

```ts:src/types/signal.d.ts
export interface Signal<T> {
  get(): T;
  set(value: T): void;
}

export function createSignal<T>(initial: T): Signal<T>;
```

## Code with Meta (Line Highlighting)

```typescript {highlight=[2,4-6]}
function greet(name: string): string {
  // This line is highlighted
  const greeting = `Hello, ${name}!`;
  // These lines are highlighted
  console.log(greeting);
  return greeting;
}
```
