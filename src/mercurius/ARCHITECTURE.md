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
<div ln:id="counter-1"
     ln:url="https://cdn.example.com/components/counter.js"
     ln:trigger="visible"
     ln:state='{"count":0}'>
  <span>0</span>
  <button>+1</button>
</div>

<!-- With loader (standalone) -->
<script type="module" src="https://cdn.example.com/ln-loader-v1.js"></script>
<div ln:id="counter-1" ...>...</div>

<!-- With inline state for large data -->
<div ln:id="app-1"
     ln:url="./app.js"
     ln:trigger="load"
     ln:state="#ln-state-app-1">
  <!-- SSR content -->
</div>
<script id="ln-state-app-1" type="ln/json">{"large":"data","nested":{"items":[1,2,3]}}<\/script>

<!-- With remote state -->
<div ln:id="user-1"
     ln:url="./user-profile.js"
     ln:trigger="idle"
     ln:state="url:https://api.example.com/user/123/state">
  <span>Loading...</span>
</div>
```

## Attributes

| Attribute | Required | Description |
|-----------|----------|-------------|
| `ln:id` | Yes | Unique identifier for the component |
| `ln:url` | Yes | ES module URL to load for hydration |
| `ln:trigger` | No | When to hydrate (default: `load`) |
| `ln:state` | No | Initial state (inline JSON, `#id` ref, or `url:` prefix) |

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
<div ln:state='{"count":0}'></div>
```

- Pros: Single HTTP request, no async loading
- Cons: HTML size increases, needs XSS escaping
- Use when: State < 1KB

### Script Reference (for medium state)

```html
<div ln:state="#ln-state-123"></div>
<script id="ln-state-123" type="ln/json">{"data":"..."}<\/script>
```

- Pros: Cleaner HTML attributes, larger capacity
- Cons: Still inline in HTML
- Use when: State 1KB - 100KB

### URL Reference (for large state)

```html
<div ln:state="url:https://api.example.com/state/123"></div>
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
<script type="module" src="ln-loader-v1.js" nonce="abc123"></script>
```

## Loader Script

`ln-loader-v1.js` (~1KB minified):

1. Scans for `[ln\\:id]` elements
2. Sets up trigger listeners (IntersectionObserver, idle callback, etc.)
3. On trigger:
   - Parse state from `ln:state`
   - Dynamic import `ln:url`
   - Call exported `hydrate(element, state)` function

### Versioning

Loader uses versioned filenames (`ln-loader-v1.js`) to:
- Prevent duplicate loading via `type="module"` deduplication
- Allow multiple versions on same page
- Enable breaking changes without conflicts

```html
<!-- These won't conflict -->
<script type="module" src="ln-loader-v1.js"></script>
<script type="module" src="ln-loader-v2.js"></script>
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
  loader_url: String         // Loader URL (default: ln-loader-v1.js)
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
  loader_url: "https://cdn.example.com/ln-loader-v1.js",
}

let output = generate_embed(config)
// output.html contains the complete snippet
```

## Integration with js/loader

The `js/loader/` directory contains:
- `ln-loader-v1.js` - Production loader
- `ln-loader-v1.min.js` - Minified version

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
src/embedding/
├── ARCHITECTURE.md    # This file
├── moon.pkg.json      # Package config
├── types.mbt          # EmbedConfig, TriggerType, StateConfig, EmbedOutput
├── serializer.mbt     # JSON serialization with XSS escaping
├── html_builder.mbt   # HTML snippet generation
└── embedding_test.mbt # Tests

js/loader/
├── ln-loader-v1.js    # Loader script (renamed from loader.js)
├── ln-loader-v1.min.js
└── loader.test.ts     # Tests
```

## Current Status (WIP)

This module is currently a **proof of concept**. The current implementation:

### What Works
- ✅ HTML snippet generation with `ln:*` attributes
- ✅ XSS escaping for inline JSON state (`escape_json_for_html`)
- ✅ Various trigger modes (load, visible, idle, none)
- ✅ Script reference state (`#id` format)
- ✅ Basic E2E tests with mock hydration components

### What's Missing (TODO)

#### 1. SSR Integration (High Priority)
The current E2E tests use **static HTML strings**, not actual SSR output:

```moonbit
// Current: Manual HTML string
let html = "<span data-count>5</span><button>+</button>"

// Goal: Generate from VNode via SSR
let vnode = Counter::render(state)
let html = @ssr.render_to_string(vnode)
```

**Task**: Create `src/js/ssr/` module that renders VNodes to HTML strings.

#### 2. Idempotent Hydration Test (High Priority)
Need to verify SSR → Hydration produces identical DOM (like Next.js/Remix/Qwik):

```typescript
// E2E test pseudocode
test("hydration is idempotent", async ({ page }) => {
  await page.goto("/ssr-test");

  // Get initial SSR HTML
  const ssrHtml = await page.locator("#app").innerHTML();

  // Wait for hydration
  await expect(page.locator("#app")).toHaveAttribute("data-hydrated", "true");

  // HTML should be identical (or semantically equivalent)
  const hydratedHtml = await page.locator("#app").innerHTML();
  expect(hydratedHtml).toBe(ssrHtml);
});
```

**Task**: Implement in `e2e/embedding/` with real MoonBit SSR output.

#### 3. Component Hydration Module (Medium Priority)
Current loader expects JS modules with `hydrate(el, state)` function.
Need MoonBit-generated component modules:

```moonbit
// src/js/component/counter.mbt
pub fn hydrate(el: @dom.Element, state: Json) -> Unit {
  // Attach event handlers, setup reactivity
}
```

**Task**: Create component export pattern for JS backend.

#### 4. State Serialization from Hooks (Medium Priority)
Hooks state needs to be serializable for resumability:

```moonbit
// During SSR
let serialized = @hooks.serialize_state(context)
// Output: {"useState:0": 5, "useEffect:1": {...}}

// During hydration
@hooks.restore_state(context, serialized)
```

**Task**: Implement in `src/js/vdom/hooks_serialization.mbt`.

#### 5. Reconcile + Hydration Mode (Medium Priority)
Current reconcile module does full diff. Need hydration mode that:
- Walks existing DOM (from SSR)
- Attaches event handlers without re-rendering
- Only updates if state differs

```moonbit
pub fn hydrate(el: @dom.Element, vnode: VNode) -> Unit {
  // Don't mutate DOM, just attach handlers
}
```

**Task**: Add `experimental_hydrate` to reconcile module.

### Architecture Evolution

```
Phase 1 (Current):
  embedding → static HTML strings → loader → mock JS hydrate()

Phase 2 (Next):
  embedding → VNode SSR → loader → MoonBit hydrate()

Phase 3 (Goal):
  Component → SSR HTML + serialized state → loader → resumable hydration
```

## Future Considerations

- WebComponents output (`<kg-counter>` custom elements)
- Streaming SSR support
- State compression (gzip in base64)
- Preload hints (`<link rel="modulepreload">`)
