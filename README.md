> **Warning: This is a Proof of Concept (PoC)**
>
> This project is experimental and under active development. APIs may change without notice. Not recommended for production use.

Most internal documents are Japanese. We will translate at `v0.2.0`

# Luna UI

**Docs**: https://luna.mizchi.workers.dev/

A reactive UI library written in [MoonBit](https://www.moonbitlang.com/) with **Island Architecture** and Fine-Grained Reactivity inspired by [Solid.js](https://www.solidjs.com/) and [Qwik](https://qwik.dev/).

- **Client-side**: Compiles to JavaScript for browser DOM rendering and hydration
- **Server-side**: Runs on native backend for high-performance SSR
- **JavaScript API**: Use from JavaScript/TypeScript via `@mizchi/luna` npm package


## Features

- **Fine-Grained Reactivity** - Signal-based reactive primitives (`Signal`, `effect`, `memo`) with automatic dependency tracking
- **Island Architecture** - Partial hydration with selective component loading
- **SSR (Server-Side Rendering)** - Render to HTML string with streaming support
- **Hydration** - Restore interactivity on SSR-rendered content with multiple trigger strategies (load, idle, visible, media)
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
| `mizchi/luna/core/render` | ✅ | ✅ | ✅ | ✅ |
| `mizchi/luna/platform/dom` | ✅ | - | - | - |

- **Core (`mizchi/luna`)**: Signals, VNode, reactive primitives - works on all targets
- **Render (`mizchi/luna/core/render`)**: HTML string rendering - works on all targets
- **DOM (`mizchi/luna/platform/dom`)**: Browser DOM rendering and hydration - JavaScript only

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
        on=@dom.events().click(fn(_) { count.update(fn(n) { n - 1 }) }),
        [@dom.text("-")],
      ),
      @dom.button(
        on=@dom.events().click(fn(_) { count.update(fn(n) { n + 1 }) }),
        [@dom.text("+")],
      ),
      @dom.button(
        on=@dom.events().click(fn(_) { count.set(0) }),
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
      on=@dom.events().click(fn(_) { show.update(fn(b) { not(b) }) }),
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

## Development

Requires [just](https://github.com/casey/just) command runner.

```bash
# Install dependencies
pnpm install

# Run all CI checks (recommended before PR)
just ci

# Type check
just check

# Run all tests
just test

# Run MoonBit tests only
just test-moonbit

# Run browser tests
just test-browser

# Run E2E tests
just test-e2e

# Build
just build

# Format code
just fmt

# Show bundle sizes
just size

# Watch mode
just watch
```

## Project Structure

```
src/
├── core/                      # Target-independent
│   ├── signal/                # Signal primitives
│   ├── vnode.mbt              # VNode definition
│   ├── render/                # HTML string rendering
│   ├── routes/                # Route matching
│   └── serialize/             # State serialization
├── platform/                  # Platform-specific
│   ├── dom/                   # Browser DOM API
│   │   ├── element/           # Low-level DOM operations (render, diff, reconcile)
│   │   └── router/            # Client-side router
│   ├── js/                    # JS-specific
│   │   └── api/               # Public API for JS (@mizchi/luna)
│   └── server_dom/            # Server-side SSR helpers
├── mercurius/                 # Shard/Island embedding
├── sol/                       # SSR framework (CLI + runtime)
├── examples/                  # Example applications
└── tests/                     # Test fixtures

js/
├── luna/                      # npm package (@mizchi/luna)
└── loader/                    # Island hydration loader (@mizchi/luna-loader)

e2e/                           # Playwright E2E tests
```

## Island Architecture

Luna supports partial hydration through Island Architecture. Components are rendered on the server and selectively hydrated on the client based on triggers:

| Trigger | Description |
|---------|-------------|
| `load` | Hydrate immediately on page load |
| `idle` | Hydrate during browser idle time (requestIdleCallback) |
| `visible` | Hydrate when element becomes visible (IntersectionObserver) |
| `media` | Hydrate when media query matches |
| `none` | Manual hydration via `__LN_HYDRATE__` |

## Sol - SSR Framework

Sol is a built-in SSR framework that integrates with Hono for server-side rendering. Create new projects with:

```bash
just sol new myapp
```

## License

MIT
