# MoonBit UI Library

A reactive UI library for MoonBit with Fine-Grained Reactivity inspired by [Solid.js](https://www.solidjs.com/).

## Features

- **Fine-Grained Reactivity** - Signal-based reactive primitives (`Signal`, `effect`, `memo`) with automatic dependency tracking
- **SSR (Server-Side Rendering)** - Render to HTML string
- **Hydration** - Restore interactivity on SSR-rendered content
- **JSX/TSX Support** - Use familiar JSX syntax via `@mizchi/ui` npm package
- **Multi-target Support** - Core signals work on js, native, wasm, wasm-gc

## Installation

### MoonBit

```json
// moon.mod.json
{
  "deps": {
    "mizchi/ui": "0.1.0"
  }
}
```

### npm (for JSX/TSX)

```bash
npm install @mizchi/ui
```

## Target Support

| Package | js | native | wasm | wasm-gc |
|---------|:--:|:------:|:----:|:-------:|
| `mizchi/ui` (core) | ✅ | ✅ | ✅ | ✅ |
| `mizchi/ui/ssr` | ✅ | ✅ | ✅ | ✅ |
| `mizchi/ui/dom` | ✅ | - | - | - |

- **Core (`mizchi/ui`)**: Signals, VNode, reactive primitives - works on all targets
- **SSR (`mizchi/ui/ssr`)**: Server-side rendering - works on all targets
- **DOM (`mizchi/ui/dom`)**: Browser DOM rendering and hydration - JavaScript only

## Usage

### MoonBit - Signals

```moonbit
// Create a signal
let count = @ui.signal(0)

// Create an effect that auto-tracks dependencies
let _ = @ui.effect(fn() {
  println("Count: " + count.get().to_string())
})

// Update triggers the effect
count.set(1)  // prints: Count: 1
```

### MoonBit - VNode and SSR

```moonbit
// Build virtual DOM
let vnode = @ui.vdiv(
  [@ui.vclass("container")],
  [
    @ui.vh1([], [@ui.vtext("Hello")]),
    @ui.vp([], [@ui.vtext_dyn(fn() { count.get().to_string() })]),
  ]
)

// Render to HTML string
let html = @ssr.render_to_string(vnode)

// Render with hydration markers
let html_with_markers = @ssr.render_to_string_with_hydration(vnode)
```

### MoonBit - DOM Rendering

```moonbit
// Render to DOM (JavaScript target only)
let container = @js_dom.document().getElementById("app")
match container {
  Some(el) => @dom.render_vnode(el, vnode)
  None => ()
}

// Or hydrate SSR content
match container {
  Some(el) => {
    let result = @dom.hydrate(el, vnode)
    // Handle result...
  }
  None => ()
}
```

### TypeScript/JSX

```tsx
// tsconfig.json
{
  "compilerOptions": {
    "jsx": "react-jsx",
    "jsxImportSource": "@mizchi/ui"
  }
}
```

```tsx
import { createSignal, get, set } from "@mizchi/ui";
import { render } from "@mizchi/ui/dom";

function Counter() {
  const count = createSignal(0);
  return (
    <div>
      <p>Count: {() => get(count)}</p>
      <button onClick={() => set(count, get(count) + 1)}>
        Increment
      </button>
    </div>
  );
}

const container = document.getElementById("app")!;
render(container, <Counter />);
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
├── *.mbt           # Core: Signal, effect, memo (all targets)
├── ssr/            # SSR rendering (all targets)
├── dom/            # DOM rendering & hydration (js only)
├── js_api/         # JavaScript API exports
└── examples/       # Example code

packages/ui/        # npm package (@mizchi/ui)
├── index.js        # Core exports
├── dom.js          # DOM rendering
├── jsx-runtime.js  # JSX runtime
└── *.d.ts          # TypeScript definitions
```

## License

MIT
