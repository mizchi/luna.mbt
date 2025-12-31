---
title: Counter
---

# Counter

A simple counter component demonstrating basic state management and event handling.

## Demo

<Island name="counter-1" :props='{"initial": 0}' trigger="visible" />

## Usage

```moonbit
let count = @signal.create(0)

@luna.div([], [
  @luna.button([onClick(fn(_) { count.set(count.get() - 1) })], [@luna.text("-")]),
  @luna.span([], [@luna.text(count.get().to_string())]),
  @luna.button([onClick(fn(_) { count.set(count.get() + 1) })], [@luna.text("+")]),
])
```

## Features

- Reactive state with signals
- Click event handling
- Increment/decrement buttons
