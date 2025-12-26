---
title: Stella
---

# Stella

Stella is a Web Components build system for Luna. It compiles MoonBit components into standalone Web Components that can be distributed and embedded anywhere.

## Features

- **MoonBit to Web Components** - Compile MoonBit UI code to standard Custom Elements
- **Signal-based Reactivity** - Fine-grained reactivity via `@wcr` runtime
- **Multiple Distribution Variants** - Auto-register, ESM export, loader-compatible
- **Loader Script** - Auto-detect and load components dynamically
- **iframe Embed** - Sandboxed embedding with postMessage communication
- **SSR/Hydration Ready** - Works with declarative shadow DOM
- **TypeScript/React Types** - Generated type definitions for consumers

## Quick Start

### 1. Create Component in MoonBit

```moonbit
// src/counter.mbt
pub fn template(props_js : @js.Any) -> String {
  let initial = @wc.get_prop_int(props_js, "initial")
  let label = @wc.get_prop_string(props_js, "label")
  let mut html = @wc.HtmlBuilder::new(0)
  html.write_string("<div class=\"counter\">")
  html.write_string("<span class=\"label\">")
  html.write_string(label)
  html.write_string(":</span>")
  html.write_string("<span class=\"value\">")
  html.write_string(initial.to_string())
  html.write_string("</span>")
  html.write_string("<button class=\"inc\">+</button>")
  html.write_string("</div>")
  html.val
}

pub fn setup(ctx_js : @js.Any) -> @js.Any {
  let ctx = @wc.WcContext::from_js(ctx_js)
  let initial = ctx.prop_int("initial")
  let label = ctx.prop_string("label")
  let disabled = ctx.prop_bool("disabled")

  // Local state
  let count = @wc.JsSignalInt::new(initial.get())

  // Sync on initial change
  let unsub_initial = initial.subscribe(fn() {
    count.set(initial.get())
    ctx.set_text(".value", count.get().to_string())
  })

  // Bind label
  let unsub_label = ctx.bind(".label", fn() { label.get() + ":" })

  // Bind disabled attribute
  let unsub_dec = ctx.bind_attr(".dec", "disabled", disabled.to_any())
  let unsub_inc = ctx.bind_attr(".inc", "disabled", disabled.to_any())

  // Event handlers
  let unsub_click = ctx.on(".inc", "click", fn() {
    count.set(count.get() + 1)
    ctx.set_text(".value", count.get().to_string())
    ctx.emit("change", count.get())
  })

  @wc.wrap_cleanup(fn() {
    unsub_initial()
    unsub_label()
    unsub_dec()
    unsub_inc()
    unsub_click()
  })
}
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
stella build counter.wc.json -o dist/.tmp/x-counter-wrapper.js

# Bundle with esbuild (see bundle.js example)
```

### 4. Use in HTML

```html
<x-counter initial="5" label="Score"></x-counter>
<script type="module" src="./x-counter.js"></script>
```

## Configuration

### stella.config.json

Main configuration for component distribution:

```json
{
  "tag": "x-counter",
  "publicPath": "https://cdn.example.com/components",
  "attributes": [
    { "name": "initial", "type": "int", "default": 0 },
    { "name": "label", "type": "string", "default": "Count" },
    { "name": "disabled", "type": "bool", "default": false }
  ],
  "events": [
    { "name": "change", "detail": { "value": "number" } }
  ],
  "slot": false,
  "ssr": { "enabled": false },
  "loader": { "enabled": true },
  "iframe": { "enabled": true, "resizable": true },
  "demo": {
    "enabled": true,
    "title": "x-counter Demo",
    "description": "A counter Web Component"
  },
  "cors": { "allowedOrigins": ["*"] }
}
```

### Attribute Types

| Type | MoonBit | HTML Example |
|------|---------|--------------|
| `string` | `String` | `label="Score"` |
| `int` | `Int` | `initial="42"` |
| `float` | `Double` | `ratio="0.5"` |
| `bool` | `Bool` | `disabled` (presence = true) |

## Output Variants

Stella generates three JavaScript variants:

### 1. Auto-Register (`x-counter.js`)

Automatically registers the custom element on load.

```html
<script type="module" src="./x-counter.js"></script>
<x-counter initial="10"></x-counter>
```

### 2. ESM Export (`x-counter-define.js`)

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

### 3. Loadable (`x-counter-loadable.js`)

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

### Local Testing

For local development, set the base URL:

```html
<script>window.STELLA_BASE_URL = 'http://localhost:3600';</script>
<script src="http://localhost:3600/loader.js"></script>
```

## iframe Embed

For sandboxed embedding with cross-origin isolation.

### Setup (Host Page)

```html
<script src="https://cdn.example.com/components/x-counter-iframe.js"></script>
```

### Declarative Usage

```html
<div data-stella-iframe="x-counter" data-initial="10" data-label="Score"></div>
```

### Programmatic Usage

```javascript
const counter = createStellaIframe('#container', {
  initial: 10,
  label: 'Score'
});

// Listen for events
counter.on('change', (detail) => {
  console.log('Value:', detail.value);
});

// Update attributes
counter.setAttr('label', 'New Label');

// Wait for ready
counter.on('ready', () => {
  console.log('Component loaded');
});
```

### Local Testing

```javascript
const counter = createStellaIframe('#container', {
  initial: 0,
  baseUrl: 'http://localhost:3600'  // Override for local dev
});
```

## MoonBit Context API

### WcContext Methods

| Method | Description |
|--------|-------------|
| `ctx.prop_int(name)` | Get Int prop as Signal |
| `ctx.prop_string(name)` | Get String prop as Signal |
| `ctx.prop_bool(name)` | Get Bool prop as Signal |
| `ctx.bind(selector, getter)` | Bind text content to getter |
| `ctx.bind_attr(selector, attr, signal)` | Bind attribute to Signal |
| `ctx.set_text(selector, text)` | Set text content directly |
| `ctx.on(selector, event, handler)` | Add event listener |
| `ctx.emit(event, value)` | Dispatch custom event |
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

// Convert to Any (for bind_attr)
let any_signal = count.to_any()
```

## Generated Files

| File | Description |
|------|-------------|
| `x-counter.js` | Auto-register variant |
| `x-counter-define.js` | ESM export variant |
| `x-counter-loadable.js` | Loadable/hydration variant |
| `x-counter.d.ts` | TypeScript declarations |
| `x-counter.react.d.ts` | React JSX types |
| `loader.js` | Component loader script |
| `x-counter-iframe.html` | iframe embed page |
| `x-counter-iframe.js` | iframe helper for host pages |
| `_headers` | CORS headers (Cloudflare/Netlify) |
| `index.html` | Demo page |
| `embed.html` | Embedding documentation |

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

## SSR / Hydration

Stella supports declarative shadow DOM for SSR:

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
stella build <config.json> [options]
  -o, --output <path>  Output file path
  -h, --help           Show help

# Create new component template
stella init <component-name>
  Creates <name>.wc.json with basic structure

# Examples
stella build counter.wc.json -o dist/x-counter.js
stella init my-widget
```

## Example Project

See `examples/stella-component/` for a complete example with:

- MoonBit counter component
- Full build pipeline
- Playwright E2E tests (20 tests)
- Demo pages

```bash
cd examples/stella-component
npm install
npm run build
npm run dev    # Preview at localhost:3600
npm test       # Run Playwright tests
```

## See Also

- [Luna UI](/luna/) - Reactivity system
- [Sol Framework](/sol/) - Full-stack SSR
- [Astra SSG](/astra/) - Static site generation
