# ADR-004: Progressive Hydration with Trigger-Based Loading

## Status

Accepted

## Context

Traditional hydration approaches have drawbacks:

1. **Full hydration**: Load all JS upfront, hydrate entire page
2. **Lazy hydration**: Defer loading but complex to implement
3. **Partial hydration**: Only hydrate interactive parts (Islands)

For optimal performance, we need:
- Minimal initial JavaScript
- Hydration only when needed
- Preserve SSR content until interactive

## Decision

Implement trigger-based progressive hydration using HTML attributes.

### Trigger Types

```moonbit
pub enum TriggerType {
  Load        // Hydrate immediately on page load
  Visible     // Hydrate when element enters viewport
  Idle        // Hydrate during browser idle time
  Interaction // Hydrate on first user interaction
  Media(String) // Hydrate when media query matches
  Never       // Never hydrate (static content)
}
```

### HTML Attribute Protocol

SSR output includes hydration metadata:

```html
<div luna:id="counter"
     luna:url="/components/counter.js"
     luna:state='{"count":0}'
     luna:trigger="visible">
  <!-- SSR content preserved -->
  <span>0</span>
</div>
```

### Client Loader

Minimal loader (~3KB) that:
1. Scans for `luna:*` attributes
2. Sets up trigger observers (IntersectionObserver, etc.)
3. Fetches and executes component scripts when triggered
4. Hydrates with preserved state

### Hydration Process

```moonbit
pub fn hydrate(container: Element, component: () -> VNode) -> Unit
```

1. Parse existing DOM structure
2. Create VNode from component
3. Reconcile differences
4. Attach event listeners

## Consequences

### Positive

- **Fast initial load**: Only loader script required
- **Lazy loading**: Components load when needed
- **SEO friendly**: Full HTML content for crawlers
- **Resilient**: Works without JS (static content)

### Negative

- **Complexity**: Multiple trigger mechanisms to maintain
- **Flash of content**: Brief moment before hydration
- **State serialization**: Must handle complex state types

### Neutral

- Similar to Astro's Islands architecture
- Requires coordination between SSR and client
