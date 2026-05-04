# ADR-003: Virtual Node Abstraction for Multi-Target Rendering

## Status

Accepted

## Context

Luna needs to render to multiple targets:

1. **Browser DOM**: Client-side rendering and hydration
2. **HTML String**: Server-side rendering (SSR/SSG)
3. **Native platforms**: Future expansion possibility

A virtual node abstraction enables:
- Single component definition for all targets
- Declarative UI description
- Efficient diffing for updates

## Decision

Define a `VNode` enum representing all possible UI elements:

### Core VNode Types

```moonbit
pub enum VNode {
  Element(VElement)           // <div>, <span>, etc.
  Text(String)                // Text content
  Fragment(Array[VNode])      // Multiple siblings
  Component(VComponent)       // Functional component
  Raw(String)                 // Raw HTML (escape hatch)
}
```

### VElement Structure

```moonbit
pub struct VElement {
  tag: String
  attrs: Map[String, String]
  events: Array[(String, EventHandler)]
  children: Array[VNode]
  key: String?
}
```

### DSL Functions

```moonbit
// Element creation
pub fn div(attrs: Array[Attr], children: Array[VNode]) -> VNode
pub fn span(attrs: Array[Attr], children: Array[VNode]) -> VNode
// ... etc

// Attribute helpers
pub fn class_(value: String) -> Attr
pub fn id(value: String) -> Attr
pub fn on_click(handler: (Event) -> Unit) -> Attr
```

### Rendering Targets

```moonbit
// Browser: VNode -> DOM Node
pub fn render(vnode: VNode, container: Element) -> Unit

// SSR: VNode -> HTML String
pub fn render_to_string(vnode: VNode) -> String
```

## Consequences

### Positive

- **Universal components**: Same code for SSR and CSR
- **Declarative**: UI as data, easy to test
- **Composable**: Components are just functions returning VNode
- **Extensible**: New node types can be added

### Negative

- **Memory overhead**: VNode tree allocated before rendering
- **Two-phase rendering**: Build tree, then render
- **Complexity**: More abstraction than direct DOM

### Neutral

- Similar to React's element model
- Enables future optimization (skip unchanged subtrees)
