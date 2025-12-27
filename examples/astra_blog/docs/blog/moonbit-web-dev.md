---
title: MoonBit for Web Development
description: Using MoonBit to build modern web applications
date: "2024-12-20"
author: Luna Team
tags:
  - moonbit
  - webdev
  - programming
layout: blog-post
---

# MoonBit for Web Development

MoonBit is a modern programming language designed for cloud and edge computing. Here's how to use it for web development.

## Why MoonBit?

- **Type Safety** - Catch errors at compile time
- **Performance** - Compiles to efficient WebAssembly or JavaScript
- **Functional** - Immutable by default with powerful pattern matching

## Basic Example

```moonbit
fn hello() -> String {
  "Hello, World!"
}

fn main {
  println(hello())
}
```

## Working with the DOM

Luna provides a type-safe DOM API:

```moonbit
fn render() -> VNode {
  h("div", { class: "container" }, [
    h("h1", {}, ["Welcome"]),
    h("p", {}, ["Built with MoonBit"])
  ])
}
```

## Signals for Reactivity

Use signals for reactive state:

```moonbit
fn Counter() -> VNode {
  let count = signal(0)
  h("button", {
    on_click: fn(_) { count.set(count.get() + 1) }
  }, [count.get().to_string()])
}
```

## Building Components

Create reusable components:

```moonbit
fn Card(title: String, content: String) -> VNode {
  h("div", { class: "card" }, [
    h("h2", {}, [title]),
    h("p", {}, [content])
  ])
}
```

## Conclusion

MoonBit offers a compelling option for web development, combining safety with performance.
