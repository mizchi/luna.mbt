# ADR-001: Shard Generation for Island Hydration

## Status

Accepted

## Context

Island Architecture requires embedding hydration metadata in HTML:

1. **Component identification**: Which script to load
2. **State serialization**: Initial props/state
3. **Trigger specification**: When to hydrate
4. **SSR content**: Pre-rendered HTML

Challenges:
- XSS prevention in serialized data
- Minimal HTML overhead
- Clear attribute naming convention

## Decision

Define a Shard as a self-contained hydratable HTML fragment.

### Shard Configuration

```moonbit
pub struct ShardConfig {
  id: String              // Component identifier
  script_url: String      // Hydration script URL
  trigger: TriggerType    // When to hydrate
  state: StateConfig      // State storage strategy
  ssr_content: String?    // Pre-rendered content
  include_loader: Bool    // Embed loader script
  loader_url: String      // Loader URL if not embedded
}
```

### State Configuration

```moonbit
pub enum StateConfig {
  Empty                   // No initial state
  Inline(String)          // In luna:state attribute
  ScriptRef(String)       // Reference to <script id="...">
  Url(String)             // Fetch from URL
}
```

### Output Format

```html
<div luna:id="counter"
     luna:url="/components/counter.js"
     luna:state='{"count":0}'
     luna:trigger="visible">
  <span>0</span>
</div>
```

### Attribute Convention

| Attribute | Purpose |
|-----------|---------|
| `luna:id` | Component identifier |
| `luna:url` | Script URL to load |
| `luna:state` | Serialized initial state |
| `luna:trigger` | Hydration trigger type |

## Consequences

### Positive

- **Self-contained**: All hydration info in HTML
- **Declarative**: No runtime configuration
- **Cacheable**: HTML can be CDN-cached
- **Inspectable**: Easy to debug in DevTools

### Negative

- **HTML size**: Adds attribute overhead
- **State limits**: Large state bloats HTML
- **Attribute parsing**: Client must parse attributes

### Neutral

- luna: prefix avoids conflicts
- Similar to Astro's island attributes
