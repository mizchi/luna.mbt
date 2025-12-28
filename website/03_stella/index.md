---
title: Stella
---

# Stella

Stella is a Web Components build system for Luna. It compiles MoonBit components into standalone Web Components that can be distributed and embedded anywhere.

## Features

- **MoonBit to Web Components** - Compile MoonBit UI code to standard Custom Elements
- **Signal-based Reactivity** - Fine-grained reactivity via `@luna_ui/wcr` runtime
- **Multiple Distribution Variants** - Auto-register, ESM export, loader-compatible
- **Loader Script** - Auto-detect and load components dynamically
- **iframe Embed** - Sandboxed embedding with postMessage communication
- **SSR/Hydration Ready** - Works with Declarative Shadow DOM
- **TypeScript/React Types** - Generated type definitions for consumers

## npm Packages

| Package | Description |
|---------|-------------|
| `@luna_ui/stella` | CLI for generating Web Component wrappers |
| `@luna_ui/wcr` | Web Components runtime (Signal, effect) |

## Quick Start

### 1. Create Component in MoonBit

```moonbit
// src/counter.mbt

// Import stella/component as @wc
// moon.pkg.json: { "import": [{ "path": "mizchi/luna/stella/component", "alias": "wc" }] }

/// Generate initial HTML template
pub fn template(props_js : @js.Any) -> String {
  let initial = get_prop_int(props_js, "initial")
  let label = get_prop_string(props_js, "label")

  let html = StringBuilder::new()
  html.write_string("<div class=\"counter\">")
  html.write_string("<span class=\"label\">")
  html.write_string(label)
  html.write_string(":</span>")
  html.write_string("<span class=\"value\">")
  html.write_string(initial.to_string())
  html.write_string("</span>")
  html.write_string("<button class=\"inc\">+</button>")
  html.write_string("</div>")
  html.to_string()
}

/// Setup reactivity and event handlers
pub fn setup(ctx_js : @js.Any) -> @js.Any {
  let ctx = @wc.WcContext::from_js(ctx_js)
  let initial = ctx.prop_int("initial")
  let label = ctx.prop_string("label")
  let disabled = ctx.prop_bool("disabled")

  // Local state
  let count = { val: initial.get() }

  // Sync on initial change
  let unsub_initial = initial.subscribe(fn() {
    count.val = initial.get()
  })

  // Bind label
  let unsub_label = ctx.bind(".label", fn() { label.get() + ":" })

  // Bind disabled attribute
  let unsub_inc = ctx.bind_attr(".inc", "disabled", disabled.raw())

  // Event handlers
  let unsub_click = ctx.on(".inc", "click", fn() {
    count.val = count.val + 1
    trigger_update(ctx_js, ".value", count.val.to_string())
  })

  wrap_cleanup(fn() {
    unsub_initial()
    unsub_label()
    unsub_inc()
    unsub_click()
  })
}

// FFI helpers
extern "js" fn get_prop_int(props : @js.Any, name : String) -> Int =
  #| (props, name) => props[name] ?? 0

extern "js" fn get_prop_string(props : @js.Any, name : String) -> String =
  #| (props, name) => props[name] ?? ''

extern "js" fn wrap_cleanup(cleanup : () -> Unit) -> @js.Any =
  #| (cleanup) => cleanup

extern "js" fn trigger_update(ctx : @js.Any, selector : String, value : String) -> Unit =
  #| (ctx, selector, value) => {
  #|   const el = ctx.shadow.querySelector(selector);
  #|   if (el) el.textContent = value;
  #| }
```

### 2. Create Component Config

```json
// counter.wc.json
{
  "tag": "x-counter",
  "module": "./counter.mbt.js",
  "attributes": [
    { "name": "initial", "type": "int", "default": 0 },
    { "name": "label", "type": "string", "default": "Count" },
    { "name": "disabled", "type": "bool", "default": false }
  ],
  "shadow": "open",
  "styles": ":host { display: inline-block; }"
}
```

### 3. Build and Bundle

```bash
# Build MoonBit to JS
moon build --target js

# Generate wrapper
npx @luna_ui/stella build counter.wc.json -o dist/x-counter.js
```

### 4. Use in HTML

```html
<x-counter initial="5" label="Score"></x-counter>
<script type="module" src="./x-counter.js"></script>
```

## MoonBit Package Setup

```json
// moon.pkg.json
{
  "import": [
    { "path": "mizchi/luna/stella/component", "alias": "wc" },
    { "path": "mizchi/js", "alias": "js" }
  ],
  "link": {
    "js": {
      "exports": ["setup", "template"],
      "format": "esm"
    }
  }
}
```

## Configuration

### Component Config (*.wc.json)

```json
{
  "tag": "x-counter",
  "module": "./counter.mbt.js",
  "attributes": [
    { "name": "initial", "type": "int", "default": 0 },
    { "name": "label", "type": "string", "default": "Count" },
    { "name": "disabled", "type": "bool", "default": false }
  ],
  "shadow": "open",
  "styles": ":host { display: block; }"
}
```

### Attribute Types

| Type | MoonBit | HTML Example |
|------|---------|--------------|
| `string` | `String` | `label="Score"` |
| `int` | `Int` | `initial="42"` |
| `float` | `Double` | `ratio="0.5"` |
| `bool` | `Bool` | `disabled` (presence = true) |

## MoonBit Context API

### WcContext Methods

| Method | Description |
|--------|-------------|
| `WcContext::from_js(ctx)` | Create context from JS object |
| `ctx.prop_int(name)` | Get Int prop as JsSignalInt |
| `ctx.prop_string(name)` | Get String prop as JsSignalString |
| `ctx.prop_bool(name)` | Get Bool prop as JsSignalBool |
| `ctx.bind(selector, getter)` | Bind text content to getter |
| `ctx.bind_attr(selector, attr, signal)` | Bind attribute to Signal |
| `ctx.on(selector, event, handler)` | Add event listener |
| `ctx.on_cleanup(fn)` | Register cleanup function |

### JsSignal API

```moonbit
let count = ctx.prop_int("count")

// Get value
let current = count.get()

// Set value
count.set(10)

// Update
count.update(fn(n) { n + 1 })

// Subscribe to changes
let unsub = count.subscribe(fn() {
  println("count changed!")
})

// Get raw signal for bind_attr
let raw = count.raw()
```

## Output Variants

Stella generates JavaScript with different loading patterns:

### Auto-Register (Default)

Automatically registers the custom element on load.

```html
<script type="module" src="./x-counter.js"></script>
<x-counter initial="10"></x-counter>
```

### ESM Export

Exports the class for manual registration.

```javascript
import { XCounter, register } from './x-counter-define.js';

// Option A: Register with default tag
register();

// Option B: Register with custom tag
register('my-counter');

// Option C: Use class directly
customElements.define('custom-counter', XCounter);
```

### Loadable

For loader and SSR hydration patterns.

```javascript
import { load, hydrate } from './x-counter-loadable.js';

// Register and hydrate all existing elements
const count = load();
console.log(`Hydrated ${count} elements`);

// Or hydrate a specific container
hydrate(document.getElementById('container'));
```

## Loader

The loader script auto-detects and loads components dynamically.

### Setup

```html
<script src="https://cdn.example.com/components/loader.js"></script>
```

### Usage

Components are loaded automatically when detected in the DOM:

```html
<x-counter initial="5"></x-counter>
<!-- Component loads automatically -->
```

### API

```javascript
// Check loaded components
console.log(Stella.loaded());

// Manually trigger load
Stella.load('x-counter');

// List available components
console.log(Stella.components());
```

## SSR / Hydration

Stella supports Declarative Shadow DOM for SSR:

```html
<x-counter initial="5" label="Score">
  <template shadowrootmode="open">
    <style>/* component styles */</style>
    <div class="counter">
      <span class="label">Score:</span>
      <span class="value">5</span>
      <button class="inc">+</button>
    </div>
  </template>
</x-counter>
<script type="module" src="./x-counter.js"></script>
```

The component detects existing shadow DOM and hydrates instead of replacing.

## CLI Reference

```bash
# Generate Web Component wrapper
npx @luna_ui/stella build <config.json> [options]
  -o, --output <path>  Output file path
  -h, --help           Show help

# Examples
npx @luna_ui/stella build counter.wc.json -o dist/x-counter.js
```

## Generated Files

| File | Description |
|------|-------------|
| `x-counter.js` | Auto-register variant |
| `x-counter-define.js` | ESM export variant |
| `x-counter-loadable.js` | Loadable/hydration variant |
| `x-counter.d.ts` | TypeScript declarations |
| `x-counter.react.d.ts` | React JSX types |

## TypeScript Usage

### Vanilla TypeScript

```typescript
import type { XCounter, XCounterProps } from './x-counter';

const counter = document.querySelector('x-counter') as XCounter;
counter.addEventListener('change', (e) => {
  console.log('Value:', e.detail.value);
});
```

### React

Add reference to your types:

```typescript
// global.d.ts
/// <reference path="./x-counter.react.d.ts" />
```

Then use in JSX:

```tsx
function App() {
  return (
    <x-counter
      initial={5}
      label="Score"
      onChange={(e) => console.log(e.detail.value)}
    />
  );
}
```

## Example Project

See `src/examples/wc_counter/` in the luna.mbt repository for a complete example.

```bash
cd src/examples/wc_counter

# Build MoonBit
moon build --target js

# Start dev server
npx vite --config vite.config.ts
# → http://localhost:3500/
```

## See Also

- [Luna UI](/luna/) - Reactivity system
- [Sol Framework](/sol/) - Full-stack SSR
- [Astra SSG](/astra/) - Static site generation
