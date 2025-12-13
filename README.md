# Luna

> **⚠️ Warning: This is a Proof of Concept (PoC)**
>
> This project is experimental and under active development. APIs may change without notice. Not recommended for production use.

A reactive UI library written in [MoonBit](https://www.moonbitlang.com/) with Fine-Grained Reactivity inspired by [Solid.js](https://www.solidjs.com/) and [Qwik](https://qwik.dev/).

- **Client-side**: Compiles to JavaScript for browser DOM rendering and hydration
- **Server-side**: Runs on native backend for high-performance SSR
- **JavaScript API**: Use from JavaScript/TypeScript via `@mizchi/luna` npm package

## Features

- **Fine-Grained Reactivity** - Signal-based reactive primitives (`Signal`, `effect`, `memo`) with automatic dependency tracking
- **SSR (Server-Side Rendering)** - Render to HTML string
- **Hydration** - Restore interactivity on SSR-rendered content
- **JSX/TSX Support** - Use familiar JSX syntax via `@mizchi/luna` npm package
- **Multi-target Support** - Core signals work on js, native, wasm, wasm-gc

## Installation

### MoonBit

```json
// moon.mod.json
{
  "deps": {
    "mizchi/luna": "0.1.0"
  }
}
```

### npm (for JSX/TSX)

```bash
npm install @mizchi/luna
```

## Target Support

| Package | js | native | wasm | wasm-gc |
|---------|:--:|:------:|:----:|:-------:|
| `mizchi/luna` (core) | ✅ | ✅ | ✅ | ✅ |
| `mizchi/luna/ssr` | ✅ | ✅ | ✅ | ✅ |
| `mizchi/luna/dom` | ✅ | - | - | - |

- **Core (`mizchi/luna`)**: Signals, VNode, reactive primitives - works on all targets
- **SSR (`mizchi/luna/ssr`)**: Server-side rendering - works on all targets
- **DOM (`mizchi/luna/dom`)**: Browser DOM rendering and hydration - JavaScript only

## Usage

### Signals - Reactive Primitives

```moonbit
// Create a signal
let count = @signal.signal(0)

// Create a computed value (memo)
let doubled = @signal.memo(fn() { count.get() * 2 })

// Create an effect that auto-tracks dependencies
let _ = @signal.effect(fn() {
  println("Count: " + count.get().to_string())
  @signal.on_cleanup(fn() { println("Cleaning up") })
})

// Update triggers the effect
count.set(1)       // prints: Count: 1
count.update(fn(n) { n + 1 })  // prints: Count: 2
```

### DOM Rendering (JavaScript target)

```moonbit
fn counter_component() -> @dom.DomNode {
  let count = @signal.signal(0)
  let doubled = @signal.memo(fn() { count.get() * 2 })

  @dom.div(class="counter", [
    @dom.h2([@dom.text("Counter")]),
    // Dynamic text updates automatically
    @dom.p([@dom.text_dyn(fn() { "Count: " + count.get().to_string() })]),
    @dom.p([@dom.text_dyn(fn() { "Doubled: " + doubled().to_string() })]),
    @dom.div(class="buttons", [
      @dom.button(
        on=@dom.on(click=Some(fn(_) { count.update(fn(n) { n - 1 }) })),
        [@dom.text("-")],
      ),
      @dom.button(
        on=@dom.on(click=Some(fn(_) { count.update(fn(n) { n + 1 }) })),
        [@dom.text("+")],
      ),
      @dom.button(
        on=@dom.on(click=Some(fn(_) { count.set(0) })),
        [@dom.text("Reset")],
      ),
    ]),
  ])
}

fn main {
  let doc = @js_dom.document()
  match doc.getElementById("app") {
    Some(el) => {
      let app = counter_component()
      @dom.render(el |> @dom.DomElement::from_jsdom, app)
    }
    None => ()
  }
}
```

### Conditional Rendering

```moonbit
fn conditional_example() -> @dom.DomNode {
  let show = @signal.signal(true)

  @dom.div([
    @dom.button(
      on=@dom.on(click=Some(fn(_) { show.update(fn(b) { not(b) }) })),
      [@dom.text_dyn(fn() { if show.get() { "Hide" } else { "Show" } })],
    ),
    @dom.show(fn() { show.get() }, fn() {
      @dom.div([@dom.text("Conditionally rendered content")])
    }),
  ])
}
```

### List Rendering

```moonbit
fn list_example() -> @dom.DomNode {
  let items : @signal.Signal[Array[String]] = @signal.signal(["A", "B", "C"])

  @dom.ul([
    @dom.for_each(fn() { items.get() }, fn(item, index) {
      @dom.li([@dom.text(item)])
    }),
  ])
}
```

### Dynamic Attributes

```moonbit
fn style_example() -> @dom.DomNode {
  let size = @signal.signal(100)

  @dom.create_element(
    "div",
    [
      ("style", @dom.attr_dynamic(fn() {
        "width: " + size.get().to_string() + "px; height: " + size.get().to_string() + "px;"
      })),
    ],
    [],
  )
}
```

## Development

```bash
# Install dependencies
pnpm install

# Run all tests
just test

# Run MoonBit tests only
just test-moonbit

# Run Node.js tests only
just test-node

# Build
just build

# Format code
just fmt
```

## Project Structure

```
src/
├── core/
│   └── signal/        # Reactive primitives (all targets)
├── platform/
│   └── dom/           # DOM rendering & hydration (js only)
├── renderer/          # HTML string rendering (SSR)
├── router/            # Client-side routing
└── examples/          # Example applications

packages/
├── luna/              # npm package (@mizchi/luna)
├── loader/            # Island hydration loader
└── cli/               # CLI tools
```

## License

MIT
