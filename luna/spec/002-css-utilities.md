# ADR-002: Atomic CSS Utilities with Automatic Deduplication

## Status

Accepted

## Context

CSS-in-JS solutions have trade-offs:

1. **Runtime CSS** (styled-components): Runtime overhead, larger bundles
2. **Build-time CSS** (Tailwind): Utility classes, requires build step
3. **Atomic CSS** (Tachyons): Minimal CSS, but verbose class names

For a WASM-first UI library, we need:
- Zero runtime CSS parsing
- Minimal CSS output size
- Type-safe style definitions
- Support for pseudo-classes and media queries

## Decision

Implement atomic CSS utilities that generate deduplicated class names at build time.

### Core API

```moonbit
// Single property
pub fn css(property: String, value: String) -> String

// Multiple properties
pub fn styles(props: Array[(String, String)]) -> String

// Combine class names
pub fn combine(classes: Array[String]) -> String
```

### Pseudo-class Support

```moonbit
pub fn hover(property: String, value: String) -> String
pub fn focus(property: String, value: String) -> String
pub fn active(property: String, value: String) -> String
```

### Media Query Support

```moonbit
pub fn at_sm(property: String, value: String) -> String  // min-width: 640px
pub fn at_md(property: String, value: String) -> String  // min-width: 768px
pub fn at_lg(property: String, value: String) -> String  // min-width: 1024px
pub fn dark(property: String, value: String) -> String   // prefers-color-scheme: dark
```

### Deduplication Strategy

Use global registries to track unique declarations:

```moonbit
priv struct Registry {
  decl_to_class: Map[String, String]  // "display:flex" -> "_0"
  mut counter: Int
}
```

Same declaration always returns same class name.

### CSS Generation

```moonbit
pub fn generate_css() -> String
```

Outputs minimal CSS with all registered declarations.

## Consequences

### Positive

- **Minimal CSS size**: Each declaration appears once
- **No runtime parsing**: Class names generated at build time
- **Type-safe**: MoonBit compiler catches typos
- **Composable**: Easy to combine and reuse styles

### Negative

- **No shorthand properties**: Must use explicit property names
- **String-based API**: Property names not validated at compile time
- **Global state**: Registry is mutable global

### Neutral

- Class names are opaque (_0, _1, etc.) - not human-readable
- Similar mental model to Tailwind but with function calls
