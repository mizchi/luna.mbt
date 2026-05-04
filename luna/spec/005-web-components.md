# ADR-005: Web Components Integration with Declarative Shadow DOM

## Status

Accepted

## Context

Islands architecture requires isolated, self-contained components. Options include:

1. **Custom framework isolation**: Scope styles/scripts manually
2. **iframes**: True isolation but heavy overhead
3. **Web Components**: Native browser isolation with Shadow DOM

Web Components provide:
- Native style encapsulation
- Standard custom element lifecycle
- Declarative Shadow DOM for SSR

## Decision

Use Web Components with Declarative Shadow DOM for island isolation.

### Server-Side Rendering

Generate Declarative Shadow DOM template:

```html
<my-counter>
  <template shadowrootmode="open">
    <style>/* scoped styles */</style>
    <span>0</span>
  </template>
</my-counter>
```

### VNode Types for Web Components

```moonbit
pub enum VNode {
  // ... other variants
  WcIsland(VWcIsland)        // Standard Web Component
  WcIslandInternalRef(...)   // With internal script reference
}

pub struct VWcIsland {
  name: String               // Custom element tag name
  url: String                // Component script URL
  state: String              // Serialized initial state
  trigger: TriggerType       // Hydration trigger
  children: Array[VNode]     // Shadow DOM content
  styles: String             // Scoped CSS
}
```

### Hydration Attributes

```html
<my-counter luna:wc-url="/components/counter.js"
            luna:wc-state='{"count":0}'
            luna:wc-trigger="load">
```

### Client Registration

```typescript
customElements.define('my-counter', class extends HTMLElement {
  connectedCallback() {
    // Attach to existing shadow root from SSR
    const shadow = this.shadowRoot;
    // Initialize Luna component
  }
});
```

## Consequences

### Positive

- **Native isolation**: Styles don't leak in/out
- **SSR support**: Declarative Shadow DOM works without JS
- **Standards-based**: Works with any framework
- **Scoped slots**: Named slots for content projection

### Negative

- **Browser support**: Declarative Shadow DOM requires modern browsers
- **Styling complexity**: Must explicitly pierce shadow boundary
- **Bundle size**: Each component needs custom element boilerplate

### Neutral

- Custom element names must contain hyphen (my-counter, not counter)
- Shadow DOM event retargeting can be confusing
