---
title: CSS Utilities
---

# CSS Utilities

Luna provides atomic CSS utilities for zero-runtime styling in MoonBit applications.

## Overview

Luna's CSS utilities offer:

- **Direct CSS API**: Use CSS property names directly (`css("display", "flex")`)
- **Automatic deduplication**: Same declarations share class names
- **Hash-based class names**: Deterministic short names (`_z5et`, `_3pgqo`...)
- **Zero client-side runtime**: CSS generation happens only at SSR time
- **Opt-in**: Only included in bundle when `@css` is imported

## Basic Usage

### Single Property

```moonbit
// Single CSS property
let flex_class = @css.css("display", "flex")  // Returns "_z5et"

// Use with elements
div(class=flex_class, [...])
```

### Multiple Properties

```moonbit
// Multiple properties at once
let card_class = @css.styles([
  ("display", "flex"),
  ("align-items", "center"),
  ("padding", "1rem"),
])  // Returns "_z5et _3m33u _8ktnx"
```

### Combining Classes

```moonbit
let base = @css.css("display", "flex")
let center = @css.css("align-items", "center")
let combined = @css.combine([base, center])  // "_z5et _3m33u"
```

## Pseudo-classes

```moonbit
// Hover state
let hover_bg = @css.hover("background", "#2563eb")

// Focus state
let focus_outline = @css.focus("outline", "2px solid blue")

// Active state
let active_scale = @css.active("transform", "scale(0.98)")

// Generic pseudo-class/element
let first_margin = @css.on(":first-child", "margin-top", "0")
```

## Media Queries

```moonbit
// Responsive breakpoints
let md_padding = @css.at_md("padding", "2rem")    // min-width: 768px
let lg_font = @css.at_lg("font-size", "1.25rem")  // min-width: 1024px

// Dark mode
let dark_bg = @css.dark("background", "#1a1a1a")

// Custom media query
let custom = @css.media("min-width: 1440px", "max-width", "1200px")
```

## Zero-Runtime Architecture

Luna's CSS utilities are designed for **zero client-side runtime**:

```
SSR Phase                        Client Phase
─────────────────────────        ─────────────────────────
@css.css("display", "flex")      class="_z5et" (string only)
        ↓                        No CSS code included
    Returns "_z5et"              in client bundle
        ↓
generate_full_css()
        ↓
<style>._z5et{display:flex}</style>
```

### Opt-in Design

CSS utilities are only included in your bundle when you import `@css`:

```moonbit
// Without @css import: 44KB bundle (no CSS code)
import "mizchi/luna/luna/signal"

// With @css import: CSS code included
import "mizchi/luna/luna/css"
```

## Build Tools

### CLI Commands

Luna provides CLI commands for CSS extraction and injection:

```bash
# Extract CSS from .mbt files
npx luna css extract src/examples/todomvc

# Minify CSS
npx luna css minify input.css -o output.min.css

# Inline CSS into JavaScript (for runtime injection)
npx luna css inline input.css -o output.js

# Inject CSS into HTML template
npx luna css inject index.html --src src/myapp
```

### Vite Plugin

For development with Vite, use the Luna CSS plugin:

```typescript
// vite.config.ts
import { lunaCss } from "@luna_ui/luna/vite-plugin";

export default defineConfig({
  plugins: [
    lunaCss({
      src: ["src/examples/todomvc"],  // Source directories
      mode: "auto",                    // "inline" | "external" | "auto"
      threshold: 4096,                 // Size threshold for auto mode
      verbose: true,                   // Enable logging
    }),
  ],
});
```

The plugin:
- Extracts CSS from `.mbt` files at build time
- Injects CSS into HTML templates
- Watches for changes and triggers HMR

### Static CSS Extraction

For production builds, extract CSS statically:

```bash
# Extract from directory
npx luna css extract src --output utilities.css

# With pretty output
npx luna css extract src --pretty

# JSON format with class mapping
npx luna css extract src --json
```

## Best Practices

### Use String Literals

Always use string literals for static extraction compatibility:

```moonbit
// Good: Can be statically extracted
@css.css("display", "flex")
@css.hover("background", "#2563eb")

// Bad: Cannot be extracted, only works at runtime
let prop = "display"
@css.css(prop, "flex")  // Warning: non-literal argument
```

### Keep CSS in SSR Code

To maintain zero runtime, use CSS utilities only in SSR code:

```moonbit
// Good: Use in static_dom (SSR only)
fn my_component() -> @static_dom.Node {
  div(class=@css.css("display", "flex"), [...])
}

// Avoid: Using in Island client code
fn my_island() -> @luna.Node[Unit] {
  // This would include CSS code in client bundle
  div(class=@css.css("display", "flex"), [...])

  // Better: Use pre-computed class strings
  div(class="_z5et _3m33u", [...])
}
```

### Dynamic Styling in Islands

For dynamic styling in client-side Islands:

```moonbit
// Option 1: Class name switching
let class_name = if is_active.get() { "_active" } else { "_inactive" }
div(class=class_name, [...])

// Option 2: CSS custom properties
div(style="--color: " + color.get(), [...])

// Option 3: Inline styles for truly dynamic values
div(style="transform: translateX(" + x.get().to_string() + "px)", [...])
```

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

## See Also

- [Signals API](/luna/api-js/signals/) - Reactive state management
- [Islands](/luna/api-js/islands/) - Island architecture
