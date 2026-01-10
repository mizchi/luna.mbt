# Luna CSS Utility Module

Atomic CSS generation for Luna with zero client-side runtime.

## Overview

Luna CSS provides two mechanisms:

1. **MoonBit Runtime** (`@css`): Generates class names at SSR time
2. **Static Extraction** (`luna css extract`): Extracts CSS from `.mbt` files at build time

Both produce **identical class names** using DJB2 hash, ensuring consistency.

## How It Works

```
┌─────────────────────────────────────────────────────────────────┐
│                        Build Time                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  .mbt files ──→ luna css extract ──→ CSS file                   │
│     │                                    │                       │
│     │  @css.css("display", "flex")       │  ._z5et{display:flex} │
│     │           ↓                        │                       │
│     │       "_z5et"                      │                       │
│     │                                    │                       │
└─────┴────────────────────────────────────┴───────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                        Runtime (Browser)                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  HTML: <div class="_z5et">              CSS: ._z5et{display:flex}│
│                                                                  │
│  No CSS generation code in client bundle!                        │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Class Name Generation

All class names are generated using DJB2 hash for determinism:

```
css("display", "flex")     → hash("display:flex")     → "_z5et"
css("display", "none")     → hash("display:none")     → "_3pgqo"
hover("color", "#fff")     → hash(":hover:color:#fff") → "_abc12"
```

**Key Properties:**
- Same declaration always produces the same class name
- Works identically in MoonBit runtime and static extraction
- `_` prefix prevents conflicts with external CSS

## Usage

### 1. MoonBit API (`@css` module)

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

### 2. Vite Plugin (Recommended)

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
// main.ts - Import CSS like Tailwind
import "virtual:luna.css";
```

This extracts CSS from all `.mbt` files and injects it via Vite's CSS pipeline.

### 3. CLI Commands

```bash
# Extract all CSS from directory
luna css extract src -o dist/styles.css

# With pretty output
luna css extract src --pretty

# Split by directory (for code splitting)
luna css extract src --split-dir --output-dir dist/css

# Inject into HTML
luna css inject index.html --src src
```

## Vite Plugin Options

```typescript
interface LunaCssPluginOptions {
  // Source directories (relative or absolute paths)
  src?: string | string[];

  // Enable directory-based CSS splitting
  split?: boolean;

  // Minimum usages for shared CSS (default: 3)
  sharedThreshold?: number;

  // Enable console logging
  verbose?: boolean;
}
```

### Virtual Modules

| Module | Description |
|--------|-------------|
| `virtual:luna.css` | All extracted CSS (use this for production) |
| `virtual:luna-shared.css` | Shared CSS only (split mode) |
| `virtual:luna-chunk/{dir}.css` | Per-directory CSS (split mode) |

> **Note**: For dev runtime, use `@luna_ui/luna/css/runtime` npm package instead of virtual modules.

### Split Mode Example

```typescript
// vite.config.ts
lunaCss({
  src: ["src"],
  split: true,
  sharedThreshold: 3,  // CSS used 3+ times → shared
})

// main.ts
import "virtual:luna-shared.css";        // Common CSS
import "virtual:luna-chunk/todomvc.css"; // Page-specific CSS
```

## CLI Reference

### extract

Extract CSS from `.mbt` files.

```bash
luna css extract <dir> [options]

Options:
  -o, --output <file>     Output file (default: stdout)
  --output-dir <dir>      Output directory (for split mode)
  --split                 Split by file
  --split-dir             Split by directory
  --shared-threshold <n>  Min usages for shared CSS (default: 3)
  --pretty                Pretty print output
  --json                  Output as JSON with class mapping
  --strict                Exit with error on warnings
  -v, --verbose           Show details
```

### inject

Inject CSS into HTML file.

```bash
luna css inject <html> --src <dir> [options]

Options:
  --src <dir>           Source directory (required)
  -o, --output <file>   Output file (default: in-place)
  -m, --mode <mode>     inline | external | auto (default: inline)
  -t, --threshold <n>   Size threshold for auto mode (default: 4096)
  --css-file <name>     External CSS filename (default: luna.css)
```

### minify

Minify CSS file.

```bash
luna css minify <file> -o <output>
```

## Development Mode

For development, use the CSS runtime for instant feedback:

```typescript
// Only in development!
import { css, hover } from "@luna_ui/luna/css/runtime";

// Generates CSS dynamically with console warnings
const cls = css("display", "flex");
// Console: [luna-css] Generated at runtime: ._z5et{display:flex}
//          → Run 'luna css extract' to pre-generate
```

## Best Practices

### 1. Use String Literals

Static extraction only works with string literals:

```moonbit
// ✓ Good - extractable at build time
@css.css("display", "flex")

// ✗ Bad - cannot be extracted
let prop = "display"
@css.css(prop, "flex")  // Works at runtime, but CSS won't be in extracted file
```

When non-literal arguments are used:
- Static extraction (`luna css extract`) cannot detect them
- MoonBit runtime still generates the class name correctly
- But the CSS rule won't exist in the pre-extracted CSS file
- Result: The element will have the class but no matching CSS rule

### 2. Keep CSS in SSR Code

For zero runtime overhead, use CSS in SSR-only components:

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
  div(class="_z5et", [...])  // Just the class name, no @css import
}
```

**Why?** `@static_dom.Node` components only run on the server (SSR). `@luna.Node` components (Islands) run in the browser, so importing `@css` would include CSS generation code in the client bundle.

### 3. Pre-extract for Production

Always extract CSS at build time:

```bash
# Build script
luna css extract src -o dist/styles.css
```

## API Reference

### Base Styles

| Function | Returns | Example |
|----------|---------|---------|
| `css(prop, val)` | Class name | `css("display", "flex")` → `"_z5et"` |
| `styles(pairs)` | Space-separated | `styles([...])` → `"_z5et _abc"` |
| `combine(classes)` | Joined | `combine([a, b])` → `"_z5et _abc"` |

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
| `generate_full_css()` | All styles (base + pseudo + media queries) |
| `reset_all()` | Clear all registries (for testing) |

Example output difference:
```css
/* generate_css() */
._z5et{display:flex}

/* generate_full_css() - includes pseudo and media */
._z5et{display:flex}
._1i41w:hover{border-color:#DB7676}
@media(min-width:768px){._abc{padding:2rem}}
```

## Static Analyzer (`analyzer/`)

MoonBit AST-based static analyzer for detecting CSS class co-occurrences.

### Usage

```bash
# Analyze MoonBit source files
luna css analyze-mbt src/luna --verbose
```

### Output

```json
{
  "cooccurrences": [
    {
      "classes": ["display:flex", "gap:8px"],
      "file": "src/components/card.mbt",
      "line": 42,
      "isStatic": true
    }
  ],
  "warnings": [
    {
      "kind": "dynamic_conditional",
      "file": "src/components/button.mbt",
      "line": 15,
      "message": "Conditional expression in class array"
    }
  ]
}
```

### Warning Types

| Kind | Description |
|------|-------------|
| `dynamic_conditional` | `if`/`match` in `class_=` array |
| `untraceable_variable` | Variable not traceable to `css()`/`styles()` |
| `dynamic_function_call` | Unknown function call result |
| `dynamic_array_construction` | Spread operator in array |

### Design Notes

- Uses `moonbitlang/parser` for MoonBit AST traversal
- Tracks `let x = css(...)` bindings across function scope
- API boundary: `analyze_file_json(source, file) -> String` (JSON)
- **Future**: May be extracted to a separate repository to minimize dependencies
