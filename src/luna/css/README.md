# Luna CSS Utility Module

Atomic CSS generation for Luna. Automatically deduplicates and compresses CSS declarations.

## Features

- **Direct CSS API**: Use CSS property names directly (`css("display", "flex")`)
- **Automatic deduplication**: Same declarations share class names
- **Minimal output**: Short class names (`_a`, `_b`, `_c`...)
- **Collision-free**: `_` prefix avoids conflicts with external CSS
- **SSR-only**: CSS rules determined at SSR time

## Basic Usage

```moonbit
// Import from luna/css
import { css, styles, combine } from "@luna/css"

// Or use re-exports from static_dom/element
import { ucss, ustyles } from "@luna/static_dom/element"

// Single property
let flex = css("display", "flex")  // "_a"

// Multiple properties
let card_class = styles([
  ("display", "flex"),
  ("align-items", "center"),
  ("padding", "1rem"),
])  // "_a _b _c"

// Use with elements
div(class=card_class, [
  text("Card content")
])
```

## Pseudo-classes

```moonbit
import { hover, focus, active, on } from "@luna/css"

// Convenience wrappers
let h = hover("background", "#2563eb")   // "_h0"
let f = focus("outline", "2px solid blue")  // "_f0"
let a = active("transform", "scale(0.98)")  // "_ac0"

// Generic pseudo-class
let before = on("::before", "content", "\"→\"")  // "_p0"
```

## Media Queries

```moonbit
import { at_md, at_lg, dark, media } from "@luna/css"

// Breakpoint wrappers
let m = at_md("padding", "2rem")  // "_m0"
let l = at_lg("font-size", "1.25rem")  // "_m1"

// Dark mode
let d = dark("background", "#1a1a1a")  // "_m2"

// Generic media query
let custom = media("min-width: 1440px", "max-width", "1200px")
```

## CSS Generation (SSR)

```moonbit
import { generate_css, generate_full_css } from "@luna/css"

// After rendering components, generate CSS
let base_css = generate_css()
// ._a{display:flex}._b{align-items:center}._c{padding:1rem}

let full_css = generate_full_css()
// Includes base + pseudo-classes + media queries
// ._a{display:flex}...
// ._h0:hover{background:#2563eb}...
// @media(min-width:768px){._m0{padding:2rem}}
```

## Static CSS Extraction (Build-time)

For complete CSS coverage including unexecuted code paths, use static extraction:

```bash
# Extract CSS from all .mbt files
just extract-css src

# Output to file
just extract-css src output=dist/styles.css

# JSON format with mapping
just extract-css-json src

# Quiet mode (no warnings)
just extract-css-quiet src

# Strict mode (error if non-literal arguments found)
just extract-css-strict src
```

This parses source files to find all `css()`, `hover()`, `media()` etc. calls.

### Non-literal Argument Warnings

The extractor warns when CSS function arguments are not string literals:

```moonbit
let prop = "display"

// ⚠ Warning: cannot be statically extracted
css(prop, "flex")

// ✓ OK: string literals can be extracted
css("display", "flex")
```

Use `--no-warn` to suppress warnings, or `--strict` to fail the build.

## Full Example

```moonbit
fn card(title: String, content: String) -> @luna.Node[Unit] {
  div(
    class=styles([
      ("display", "flex"),
      ("flex-direction", "column"),
      ("padding", "1.5rem"),
      ("border-radius", "0.5rem"),
      ("background", "white"),
      ("box-shadow", "0 1px 3px rgba(0,0,0,0.1)"),
    ]) + " " + hover("box-shadow", "0 4px 12px rgba(0,0,0,0.15)")
       + " " + dark("background", "#1e1e1e")
       + " " + at_md("padding", "2rem"),
    [
      h2(class=css("font-size", "1.25rem"), [text(title)]),
      p(class=css("color", "#666"), [text(content)]),
    ]
  )
}

// In your page render:
fn page() -> @luna.Node[Unit] {
  html(lang="en", [
    head([
      style_(generate_full_css()),  // Inject generated CSS
    ]),
    body([
      card("Hello", "World"),
    ])
  ])
}
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

## Build Tools

### CSS Minification

Minify CSS without changing class names (safe for existing templates):

```bash
# Minify a CSS file
just minify-css input.css output=output.min.css

# Minify Astra CSS
just minify-astra-css
```

Typical reduction: ~24%

### CSS Extraction

Extract CSS utilities from source code (static analysis):

```bash
# Extract from directory
just extract-css src

# With file output
just extract-css src output=utilities.css
```

### CSS Injection

Append extracted CSS to existing stylesheet:

```bash
just inject-utility-css
```

## Architecture Considerations

### Single-Process SSR (Recommended)

CSS utilities work best with single-process SSR:

```moonbit
fn render_page() -> String {
  // 1. Render components (populates CSS registry)
  let html = render_to_string(app())

  // 2. Generate CSS from registry
  let css = @css.generate_full_css()

  // 3. Inject CSS into HTML
  "<style>" + css + "</style>" + html
}
```

### Multi-Process Builds (e.g., Astra)

For worker-based parallel builds, use **static extraction** instead of runtime generation:

```bash
# Before build: extract CSS from source
just extract-css src output=utilities.css

# Build includes the pre-extracted CSS
```

This is because each worker has its own CSS registry that cannot be merged.

## Best Practices

### Use String Literals

Always use string literals for static extraction compatibility:

```moonbit
// ✓ Good - can be statically extracted
css("display", "flex")
hover("background", "#2563eb")

// ✗ Bad - cannot be extracted, only works at runtime
let prop = "display"
css(prop, "flex")
```

### CSS Variables for Theming

Use CSS variables for theme-dependent values:

```moonbit
// Works with light/dark themes
css("color", "var(--text-color)")
css("background", "var(--bg-color)")
dark("background", "var(--dark-bg)")
```

### Combine with Semantic Classes

Hybrid approach - utilities for layout, semantic for complex styles:

```moonbit
// Utilities for common patterns
let layout = styles([
  ("display", "flex"),
  ("gap", "1rem"),
])

// Semantic class for complex/themed styles
h("div", [
  attr("class", layout + " card-component"),
], [...])
```

## Comparison with Alternatives

| Approach | Compression | Code Changes | Runtime |
|----------|-------------|--------------|---------|
| CSS Utilities | Auto-dedup | New code style | SSR |
| CSS Minify | ~24% | None | Build |
| CSS Factorize | ~52% | Template rewrite | Build |
