# ADR-003: MDX and Custom Component Integration

## Status

Accepted

## Context

Pure Markdown is limiting for interactive documentation:

1. **Static content only**: No interactive examples
2. **No component reuse**: Copy-paste for common patterns
3. **Limited styling**: Basic Markdown formatting

MDX (Markdown + JSX) enables:
- Embedding React/JSX components in Markdown
- Interactive code examples
- Reusable documentation components

## Decision

Support MDX with Web Component conversion for Luna compatibility.

### MDX Parsing

```moonbit
pub enum MdNode {
  // ... standard Markdown nodes
  JsxComponent(JsxComponentEmbed)  // <Counter initial={5} />
}

pub struct JsxComponentEmbed {
  tag: String                       // Component name
  attrs: Array[(String, MdxAttrValue)]
  children: String                  // Inner content
  self_closing: Bool
}
```

### Attribute Value Types

```moonbit
pub enum MdxAttrValue {
  StringLiteral(String)    // prop="value"
  Expression(String)       // prop={expression}
  Boolean                  // prop (true when present)
}
```

### Web Component Conversion

JSX components are converted to Web Components:

```mdx
<Counter initial={5} />
```

Becomes:

```html
<luna-counter luna:wc-url="/components/counter.js"
              luna:wc-state='{"initial":5}'>
  <template shadowrootmode="open">
    <!-- SSR content -->
  </template>
</luna-counter>
```

### Component Resolution

1. Check `components_dir` for matching component
2. Convert PascalCase to kebab-case (Counter → luna-counter)
3. Serialize props to JSON state
4. Apply hydration trigger (default: load)

## Consequences

### Positive

- **Rich documentation**: Interactive examples inline
- **Familiar syntax**: JSX-like component usage
- **SSR support**: Components render server-side
- **Standard output**: Web Components work everywhere

### Negative

- **Parsing complexity**: JSX in Markdown is tricky
- **Naming constraints**: Must follow Web Component naming
- **Build step required**: Components must be pre-compiled

### Neutral

- Similar to Astro's component islands
- Expression evaluation is limited (JSON-serializable)
