# Embedding Module Architecture

Portable, resumable UI snippets that can be embedded anywhere.

## Overview

This module generates self-contained HTML snippets that include:
- SSR-rendered content
- Serialized initial state
- Hydration trigger configuration
- Loader script reference

Inspired by [Qwik's Resumability](https://qwik.dev/docs/concepts/resumable/) and [Astro's Client Directives](https://docs.astro.build/en/reference/directives-reference/).

## HTML Output Format

```html
<!-- Minimal snippet -->
<div luna:id="counter-1"
     luna:url="https://cdn.example.com/components/counter.js"
     luna:client-trigger="visible"
     luna:state='{"count":0}'>
  <span>0</span>
  <button>+1</button>
</div>

<!-- With loader (standalone) -->
<script type="module" src="https://cdn.example.com/luna-loader-v1.js"></script>
<div luna:id="counter-1" ...>...</div>

<!-- With inline state for large data -->
<div luna:id="app-1"
     luna:url="./app.js"
     luna:client-trigger="load"
     luna:state="#luna-state-app-1">
  <!-- SSR content -->
</div>
<script id="luna-state-app-1" type="luna/json">{"large":"data","nested":{"items":[1,2,3]}}<\/script>

<!-- With remote state -->
<div luna:id="user-1"
     luna:url="./user-profile.js"
     luna:client-trigger="idle"
     luna:state="url:https://api.example.com/user/123/state">
  <span>Loading...</span>
</div>
```

## Attributes

| Attribute | Required | Description |
|-----------|----------|-------------|
| `luna:id` | Yes | Unique identifier for the component |
| `luna:url` | Yes | ES module URL to load for hydration |
| `luna:client-trigger` | No | When to hydrate (default: `load`) |
| `luna:state` | No | Initial state (inline JSON, `#id` ref, or `url:` prefix) |

## Trigger Types

Following Astro's naming convention:

| Trigger | Description | Implementation |
|---------|-------------|----------------|
| `load` | Hydrate on page load | `DOMContentLoaded` event |
| `idle` | Hydrate when browser is idle | `requestIdleCallback` |
| `visible` | Hydrate when element enters viewport | `IntersectionObserver` |
| `media:QUERY` | Hydrate when media query matches | `matchMedia` |
| `none` | Never auto-hydrate (manual only) | No automatic trigger |

## State Formats

### Inline JSON (default for small state)

```html
<div luna:state='{"count":0}'></div>
```

- Pros: Single HTTP request, no async loading
- Cons: HTML size increases, needs XSS escaping
- Use when: State < 1KB

### Script Reference (for medium state)

```html
<div luna:state="#luna-state-123"></div>
<script id="luna-state-123" type="luna/json">{"data":"..."}<\/script>
```

- Pros: Cleaner HTML attributes, larger capacity
- Cons: Still inline in HTML
- Use when: State 1KB - 100KB

### URL Reference (for large state)

```html
<div luna:state="url:https://api.example.com/state/123"></div>
```

- Pros: Minimal HTML size, CDN cacheable
- Cons: Extra HTTP request, latency
- Use when: State > 100KB or needs caching

## Security Considerations

### XSS Prevention for Inline JSON

All JSON embedded in HTML must escape:
- `</` → `<\/` (prevents `</script>` injection)
- `<` before `s` → `\u003c` (additional safety)

```moonbit
fn escape_json_for_html(json: String) -> String {
  json.replace("</", "<\\/")
}
```

### Content Security Policy

The loader supports CSP nonces:

```html
<script type="module" src="luna-loader-v1.js" nonce="abc123"></script>
```

## Loader Script

`luna-loader-v1.js` (~1KB minified):

1. Scans for `[ln\\:id]` elements
2. Sets up trigger listeners (IntersectionObserver, idle callback, etc.)
3. On trigger:
   - Parse state from `luna:state`
   - Dynamic import `luna:url`
   - Call exported `hydrate(element, state)` function

### Versioning

Loader uses versioned filenames (`luna-loader-v1.js`) to:
- Prevent duplicate loading via `type="module"` deduplication
- Allow multiple versions on same page
- Enable breaking changes without conflicts

```html
<!-- These won't conflict -->
<script type="module" src="luna-loader-v1.js"></script>
<script type="module" src="luna-loader-v2.js"></script>
```

## API

### EmbedConfig

```moonbit
struct EmbedConfig {
  id: String
  script_url: String
  trigger: TriggerType       // Load | Idle | Visible | Media(String) | None
  state: StateConfig         // Inline(String) | ScriptRef(String) | Url(String) | Empty
  ssr_content: String?       // Pre-rendered HTML or None
  include_loader: Bool       // Include loader script tag
  loader_url: String         // Loader URL (default: luna-loader-v1.js)
}
```

### Output

```moonbit
struct EmbedOutput {
  html: String                    // Complete HTML snippet
  head_scripts: Array[String]     // Scripts to inject in <head> (for SSR)
  state_scripts: Array[String]    // State <script> tags (if using ScriptRef)
}
```

### Usage

```moonbit
let config = EmbedConfig::{
  id: "counter-1",
  script_url: "https://cdn.example.com/counter.js",
  trigger: Visible,
  state: Inline(@json.stringify(initial_state)),
  ssr_content: Some(@ssr.render_to_string(vnode)),
  include_loader: true,
  loader_url: "https://cdn.example.com/luna-loader-v1.js",
}

let output = generate_embed(config)
// output.html contains the complete snippet
```

## Integration with js/loader

The `js/loader/` directory contains:
- `luna-loader-v1.js` - Production loader
- `luna-loader-v1.min.js` - Minified version

Loader expects components to export:

```typescript
// counter.js
export function hydrate(element: HTMLElement, state: unknown): void {
  // Attach event handlers, set up reactivity
}

// Optional: for render mode (no SSR content)
export function render(element: HTMLElement, state: unknown): void {
  // Render from scratch
}
```

## File Structure

```
src/stella/
├── ARCHITECTURE.md      # This file
├── moon.pkg.json        # Package config
├── types.mbt            # ShardConfig, StateConfig, ShardOutput
├── serializer.mbt       # JSON serialization with XSS escaping
├── html_builder.mbt     # HTML snippet generation
├── shard_test.mbt       # Tests
└── component/           # Component codegen
    ├── codegen.mbt      # Code generation for hydration modules
    ├── context.mbt      # Component context
    └── types.mbt        # Component types

src/luna/render/
├── render_to_string.mbt # VNode → HTML SSR rendering
└── ssr_test.mbt         # SSR tests (1400+ lines)

src/luna/dom/client/
├── hydrate.mbt          # VNode hydration (864 lines)
├── hydrate_test.mbt     # Hydration tests (1400+ lines)
└── repair/              # Experimental hydration repair

js/loader/
├── luna-loader-v1.js    # Loader script
├── luna-loader-v1.min.js
└── loader.test.ts       # Tests
```

## Current Status

### ✅ Implemented

| Feature | Location | Description |
|---------|----------|-------------|
| **SSR Rendering** | `src/luna/render/render_to_string.mbt` | VNode → HTML with `render_to_string` and `render_to_string_with_hydration` |
| **Hydration** | `src/luna/dom/client/hydrate.mbt` | Full hydration with mismatch detection and recovery |
| **Hydration Markers** | SSR output | `sol:hk="N"` attributes for dynamic elements |
| **Dynamic Text** | Hydration | `<!--t:N-->...<!--/t-->` comment markers |
| **Show/For** | Hydration | `<!--s:N-->...<!--/s-->`, `<!--f:N-->...<!--/f-->` markers |
| **Event Handlers** | Hydration | Automatic attachment during hydration |
| **Dynamic Attributes** | Hydration | Effect-based attribute updates |
| **Shard Generation** | `src/stella/` | HTML snippet generation with `luna:*` attributes |
| **XSS Escaping** | `serializer.mbt` | Safe JSON embedding in HTML |
| **Trigger Modes** | Loader | load, visible, idle, media, none |
| **Unit Tests** | `hydrate_test.mbt` | 1400+ lines covering all hydration scenarios |

### ⚠️ Partial / Needs Improvement

| Feature | Status | Notes |
|---------|--------|-------|
| **E2E Browser Tests** | Partial | Unit tests run in jsdom; need Playwright tests for real browser verification |
| **Hydration Mode** | Recovery-based | On mismatch, re-renders entire tree instead of surgical fixes |
| **Component Export** | Undocumented | Pattern for MoonBit → JS module exports needs documentation |

### ❌ Not Yet Implemented

| Feature | Priority | Description |
|---------|----------|-------------|
| **State Serialization** | Medium | Serialize/restore hooks state for resumability |
| **Pure Hydration Mode** | Low | Attach handlers only, never mutate DOM |

## Hydration Flow

```
SSR (Server):
  VNode → render_to_string_with_hydration() → HTML with sol:hk markers

Client:
  1. Loader detects luna:id elements
  2. Trigger fires (load/visible/idle)
  3. Dynamic import component module
  4. Call hydrate(container, vnode)
     - Walk DOM tree matching VNode structure
     - Attach event handlers to elements with sol:hk
     - Set up effects for dynamic attributes
     - On mismatch: warn + re-render (recoverable)
```

## Usage Example

```moonbit
// Server-side rendering
let vnode = div([
  button(onClick=handler, [text("Click me")]),
  span([text_dyn(count_signal)]),
])
let html = @render.render_to_string_with_hydration(vnode)
// Output: <div><button sol:hk="0">Click me</button><span><!--t:1-->0<!--/t--></span></div>

// Client-side hydration
@client.hydrate(container, vnode)
// - Finds button with sol:hk="0", attaches onClick handler
// - Finds text marker t:1, sets up effect for count_signal
```

## Remaining Work

### 1. E2E Browser Tests (High Priority)

Add Playwright tests to verify hydration in real browsers:

```typescript
test("hydration attaches handlers correctly", async ({ page }) => {
  await page.goto("/counter");

  // Verify SSR content is present
  await expect(page.locator("button")).toHaveText("0");

  // Click should work after hydration
  await page.locator("button").click();
  await expect(page.locator("button")).toHaveText("1");
});
```

### 2. State Serialization (Medium Priority)

For full resumability, serialize signal state during SSR:

```moonbit
// During SSR
let state_json = @signal.serialize_tracked_state()
// Embed in HTML: <script type="luna/state">{"signals":[...]}</script>

// During hydration
@signal.restore_state(parsed_json)
```

### 3. Documentation (Low Priority)

- Document component export pattern for loader compatibility
- Add examples for custom hydration scenarios

## Future Considerations

- WebComponents output (`<luna-counter>` custom elements)
- Streaming SSR support
- State compression (gzip in base64)
- Preload hints (`<link rel="modulepreload">`)
