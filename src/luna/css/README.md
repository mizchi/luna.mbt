# Luna CSS Utility Module

Atomic CSS generation for Luna. Automatically deduplicates and compresses CSS declarations using deterministic hash-based class names.

## Features

- **Direct CSS API**: Use CSS property names directly (`css("display", "flex")`)
- **Automatic deduplication**: Same declarations share class names
- **Hash-based output**: Deterministic class names (`_z5et`, `_3pgqo`...)
- **Collision-free**: `_` prefix avoids conflicts with external CSS
- **Opt-in**: Only included in bundle when `@css` is imported

## Basic Usage

```moonbit
// Import from luna/css
import { css, styles, combine } from "@luna/css"

// Single property
let flex = css("display", "flex")  // "_z5et"

// Multiple properties
let card_class = styles([
  ("display", "flex"),
  ("align-items", "center"),
  ("padding", "1rem"),
])  // "_z5et _3m33u _8ktnx"

// Use with elements
div(class=card_class, [
  text("Card content")
])
```

## Pseudo-classes

```moonbit
import { hover, focus, active, on } from "@luna/css"

// Convenience wrappers
let h = hover("background", "#2563eb")
let f = focus("outline", "2px solid blue")
let a = active("transform", "scale(0.98)")

// Generic pseudo-class
let before = on("::before", "content", "\"→\"")
```

## Media Queries

```moonbit
import { at_md, at_lg, dark, media } from "@luna/css"

// Breakpoint wrappers
let m = at_md("padding", "2rem")
let l = at_lg("font-size", "1.25rem")

// Dark mode
let d = dark("background", "#1a1a1a")

// Generic media query
let custom = media("min-width: 1440px", "max-width", "1200px")
```

## Build Tools

### CLI Commands

```bash
# Extract CSS from .mbt files
npx luna css extract src/examples/todomvc

# Minify CSS
npx luna css minify input.css -o output.min.css

# Inline CSS into JavaScript
npx luna css inline input.css -o output.js

# Inject CSS into HTML
npx luna css inject index.html --src src/myapp
```

### Vite Plugin

```typescript
import { lunaCss } from "@luna_ui/luna/vite-plugin";

export default defineConfig({
  plugins: [
    lunaCss({
      src: ["src/examples/todomvc"],
      mode: "auto",
      threshold: 4096,
      verbose: true,
    }),
  ],
});
```

## Zero-Runtime Architecture

Luna's CSS utilities are designed for **zero client-side runtime**:

```
SSR Bundle (static_dom)          Client Bundle (Island)
───────────────────────          ─────────────────────────
@css.css() → "_z5et"             class="_z5et" (string only)
@css.hover() → "_1i41w"          No CSS code included
generate_full_css()
```

**Verification**: Island client bundles contain 0 CSS-related code.

## Opt-in Design

CSS utilities are only included in your bundle when you import `@css`:

| Example | Imports @css | Bundle Size | CSS Code |
|---------|-------------|-------------|----------|
| hello_luna | No | 44KB | Not included |
| todomvc | Yes | 424KB | Included |

## API Reference

### Base Styles

| Function | Description | Example |
|----------|-------------|---------|
| `css(prop, val)` | Single declaration | `css("display", "flex")` |
| `styles(pairs)` | Multiple declarations | `styles([("a", "b"), ...])` |
| `combine(classes)` | Join class names | `combine([c1, c2])` |

### Pseudo-classes

| Function | Description |
|----------|-------------|
| `on(pseudo, prop, val)` | Generic pseudo |
| `hover(prop, val)` | :hover |
| `focus(prop, val)` | :focus |
| `active(prop, val)` | :active |

### Media Queries

| Function | Condition |
|----------|-----------|
| `media(cond, prop, val)` | Generic |
| `at_sm(prop, val)` | min-width: 640px |
| `at_md(prop, val)` | min-width: 768px |
| `at_lg(prop, val)` | min-width: 1024px |
| `at_xl(prop, val)` | min-width: 1280px |
| `dark(prop, val)` | prefers-color-scheme: dark |

### Generation

| Function | Description |
|----------|-------------|
| `generate_css()` | Base styles only |
| `generate_full_css()` | All styles (base + pseudo + media) |
| `reset_all()` | Clear all registries (testing) |
