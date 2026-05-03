---
title: CSS Utilities
---

# CSS Utilities

Luna provides atomic CSS utilities with zero client-side runtime for MoonBit applications.

## Overview

Luna CSS provides two mechanisms that produce **identical class names**:

1. **MoonBit Runtime** (`@css`): Generates class names at SSR time
2. **Static Extraction** (`luna css extract`): Extracts CSS from `.mbt` files at build time

Both use DJB2 hash for deterministic class name generation, ensuring consistency.

## How It Works

```
Build Time                              Runtime (Browser)
──────────────────────────────          ──────────────────────────────
.mbt files                              HTML: <div class="_z5et">
    │                                   CSS:  ._z5et{display:flex}
    ▼
luna css extract → CSS file             No CSS generation code!
    │
@css.css("display", "flex")
    ▼
Returns "_z5et"
```

## Basic Usage

### MoonBit API

```moonbit
// Single property
let flex_class = @css.css("display", "flex")  // "_z5et"

// Multiple properties
let card = @css.styles([
  ("display", "flex"),
  ("padding", "1rem"),
])  // "_z5et _8ktnx"

// Pseudo-classes
let hover_bg = @css.hover("background", "#2563eb")

// Media queries
let responsive = @css.at_md("padding", "2rem")

// Use in elements
div(class=flex_class, [...])
```

### Vite Plugin (Recommended)

Import CSS like Tailwind:

```typescript
// vite.config.ts
import { lunaCss } from "@luna_ui/luna/vite-plugin";

export default defineConfig({
  plugins: [
    lunaCss({
      src: ["src"],       // Source directories with .mbt files
      verbose: true,
    }),
  ],
});
```

```typescript
// main.ts
import "virtual:luna.css";  // All extracted CSS
```

### CLI Commands

```bash
# Extract all CSS
luna css extract src -o dist/styles.css

# Split by directory (for code splitting)
luna css extract src --split-dir --output-dir dist/css

# Inject into HTML
luna css inject index.html --src src
```

## Vite Plugin Options

```typescript
interface LunaCssPluginOptions {
  src?: string | string[];     // Source directories
  split?: boolean;             // Enable directory-based splitting
  sharedThreshold?: number;    // Min usages for shared CSS (default: 3)
  verbose?: boolean;           // Enable logging
}
```

### Virtual Modules

| Module | Description |
|--------|-------------|
| `virtual:luna.css` | All extracted CSS |
| `virtual:luna-shared.css` | Shared CSS only (split mode) |
| `virtual:luna-chunk/{dir}.css` | Per-directory CSS (split mode) |

### Split Mode

For large applications with code splitting:

```typescript
lunaCss({
  src: ["src"],
  split: true,
  sharedThreshold: 3,  // CSS used 3+ times → shared
})
```

```typescript
// Import shared + page-specific CSS
import "virtual:luna-shared.css";
import "virtual:luna-chunk/todomvc.css";
```

## Best Practices

### 1. Use String Literals

Static extraction only works with literals:

```moonbit
// ✓ Good - extractable
@css.css("display", "flex")

// ✗ Bad - cannot be extracted
let prop = "display"
@css.css(prop, "flex")
```

When non-literal arguments are used:
- Static extraction cannot detect them
- MoonBit runtime still generates the class name
- But the CSS rule won't exist in the extracted file
- Result: Element has class but no matching CSS

### 2. Keep CSS in SSR Code

For zero runtime overhead:

```moonbit
// ✓ Good - SSR component (server-side only)
fn my_component() -> @static_dom.Node {
  div(class=@css.css("display", "flex"), [...])
}

// ✗ Avoid - Island component (runs in browser)
fn my_island() -> @luna.Node[Unit] {
  // This includes @css module in client bundle!
  div(class=@css.css("display", "flex"), [...])
}

// ✓ Better for Islands - use pre-computed class string
fn my_island() -> @luna.Node[Unit] {
  div(class="_z5et", [...])  // No @css import needed
}
```

**Why?** `@static_dom.Node` components only run on the server. `@luna.Node` components run in the browser, so importing `@css` would include CSS generation code in the client bundle.

### 3. Dynamic Styling in Islands

```moonbit
// Class name switching
let class_name = if is_active.get() { "_active" } else { "_inactive" }
div(class=class_name, [...])

// CSS custom properties
div(style="--color: " + color.get(), [...])

// Inline styles for dynamic values
div(style="transform: translateX(" + x.get().to_string() + "px)", [...])
```

## Development Mode

### Missing CSS Detection

The dev runtime automatically detects missing CSS rules and generates them at runtime with console warnings:

```typescript
import {
  initCssRuntime,
  css,
  hover,
  hasClass,
  getGeneratedCount
} from "@luna_ui/luna/css/runtime";

// Initialize with options
initCssRuntime({
  warnOnGenerate: true,  // Show warnings (default: true)
  verbose: false,        // Log all generations
});

// If CSS was pre-extracted, this returns existing class
// If missing, generates at runtime and warns
const cls = css("display", "flex");
// Console: [luna-css] Generated at runtime: ._z5et { display: flex }
//          → Consider running 'luna css extract' to pre-generate CSS

// Check if a class exists in stylesheets
if (!hasClass("_z5et")) {
  console.log("CSS rule missing!");
}

// Get count of runtime-generated rules
console.log(`Generated ${getGeneratedCount()} rules at runtime`);
```

### Use Cases

1. **Development Hot-Reload**: Catch missing CSS when editing MoonBit code
2. **Debug Production Issues**: Identify CSS rules not captured by static extraction
3. **Dynamic CSS Fallback**: Ensure styles work even if extraction misses edge cases

### Runtime API

| Function | Description |
|----------|-------------|
| `initCssRuntime(opts)` | Initialize with options |
| `css(prop, val)` | Generate/check base style |
| `hover(prop, val)` | Generate/check hover style |
| `hasClass(className)` | Check if class exists in any stylesheet |
| `getGeneratedCss()` | Get all runtime-generated CSS as string |
| `getGeneratedCount()` | Count of runtime-generated rules |
| `resetRuntime()` | Clear runtime state (testing) |

> **Warning**: The dev runtime adds ~5KB to your bundle. Only import it during development, not in production builds.

## API Reference

### Base Styles

| Function | Returns | Example |
|----------|---------|---------|
| `css(prop, val)` | Class name | `"_z5et"` |
| `styles(pairs)` | Space-separated | `"_z5et _abc"` |
| `combine(classes)` | Joined | `"_z5et _abc"` |

### Pseudo-classes

| Function | Selector |
|----------|----------|
| `on(pseudo, prop, val)` | Custom |
| `hover(prop, val)` | `:hover` |
| `focus(prop, val)` | `:focus` |
| `active(prop, val)` | `:active` |

### Media Queries

| Function | Condition |
|----------|-----------|
| `media(cond, prop, val)` | Custom |
| `at_sm(prop, val)` | `min-width: 640px` |
| `at_md(prop, val)` | `min-width: 768px` |
| `at_lg(prop, val)` | `min-width: 1024px` |
| `at_xl(prop, val)` | `min-width: 1280px` |
| `dark(prop, val)` | `prefers-color-scheme: dark` |

### Generation (SSR only)

| Function | Description |
|----------|-------------|
| `generate_css()` | Base styles only (`css()`, `styles()`) |
| `generate_full_css()` | All styles (base + pseudo + media) |
| `reset_all()` | Clear all registries (testing) |

Output example:
```css
/* generate_css() */
._z5et{display:flex}

/* generate_full_css() */
._z5et{display:flex}
._1i41w:hover{border-color:#DB7676}
@media(min-width:768px){._abc{padding:2rem}}
```

## See Also

- [Signals API](/luna/api-js/signals/) - Reactive state management
- [Islands](/luna/api-js/islands/) - Island architecture
