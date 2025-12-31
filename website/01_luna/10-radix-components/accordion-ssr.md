---
title: Accordion (SSR)
---

# Accordion (SSR + Hydration)

This demo shows **true SSR+Hydration**: the HTML is rendered server-side, and JavaScript only adds interactivity.

## Demo

<Island name="accordion-ssr" :props='{"open": ["item-1"]}' trigger="visible">
  <div style="display: flex; flex-direction: column; border: 1px solid var(--border-color, #374151); border-radius: 0.75rem; overflow: hidden; background: var(--sidebar-bg, #1f2937);">
    <div data-accordion-item="item-1" data-state="open">
      <button data-accordion-trigger style="width: 100%; padding: 1rem; display: flex; justify-content: space-between; align-items: center; background: transparent; border: none; border-bottom: 1px solid var(--border-color, #374151); color: var(--text-color, #e5e7eb); cursor: pointer; font-size: 0.875rem; font-weight: 500; text-align: left;">
        What is Luna?
        <span data-arrow style="transition: transform 0.2s;">▼</span>
      </button>
      <div data-accordion-content style="overflow: hidden; background: var(--bg-color, #111827);">
        <div style="padding: 1rem; color: var(--text-muted, #9ca3af); font-size: 0.875rem; line-height: 1.5;">
          Luna is a blazing-fast reactive UI framework written in MoonBit, featuring Island Architecture for optimal performance.
        </div>
      </div>
    </div>
    <div data-accordion-item="item-2" data-state="closed">
      <button data-accordion-trigger style="width: 100%; padding: 1rem; display: flex; justify-content: space-between; align-items: center; background: transparent; border: none; border-bottom: 1px solid var(--border-color, #374151); color: var(--text-color, #e5e7eb); cursor: pointer; font-size: 0.875rem; font-weight: 500; text-align: left;">
        How does SSR+Hydration work?
        <span data-arrow style="transition: transform 0.2s;">▼</span>
      </button>
      <div data-accordion-content style="max-height: 0; overflow: hidden; background: var(--bg-color, #111827);">
        <div style="padding: 1rem; color: var(--text-muted, #9ca3af); font-size: 0.875rem; line-height: 1.5;">
          The HTML is rendered at build time (SSR). When visible, JavaScript loads and attaches event handlers to existing DOM elements - no re-rendering needed!
        </div>
      </div>
    </div>
    <div data-accordion-item="item-3" data-state="closed">
      <button data-accordion-trigger style="width: 100%; padding: 1rem; display: flex; justify-content: space-between; align-items: center; background: transparent; border: none; color: var(--text-color, #e5e7eb); cursor: pointer; font-size: 0.875rem; font-weight: 500; text-align: left;">
        What are the benefits?
        <span data-arrow style="transition: transform 0.2s;">▼</span>
      </button>
      <div data-accordion-content style="max-height: 0; overflow: hidden; background: var(--bg-color, #111827);">
        <div style="padding: 1rem; color: var(--text-muted, #9ca3af); font-size: 0.875rem; line-height: 1.5;">
          Instant content visibility (no loading spinner), better SEO, smaller JavaScript bundles, and smoother user experience.
        </div>
      </div>
    </div>
  </div>
</Island>

## How It Works

### 1. SSR (Build Time)
The HTML inside `<Island>` is rendered directly into the page at build time. Users see content immediately.

### 2. Hydration (Runtime)
When `trigger="visible"` fires:
1. JavaScript loads the `accordion-ssr.js` module
2. `hydrate(element, state, id)` is called
3. Event handlers are attached to existing DOM
4. **No `innerHTML` replacement** - DOM is preserved

### Code Pattern

```javascript
// accordion-ssr.js
export function hydrate(element, state, name) {
  // Find existing DOM elements (rendered by SSR)
  const items = element.querySelectorAll('[data-accordion-item]');

  items.forEach(item => {
    const trigger = item.querySelector('[data-accordion-trigger]');
    const content = item.querySelector('[data-accordion-content]');

    // Attach event handler to existing element
    trigger.onclick = () => {
      // Toggle open/closed state
    };
  });

  element.dataset.hydrated = 'true';
}
```

### Comparison

| Approach | Initial Load | JavaScript | SEO |
|----------|--------------|------------|-----|
| Client-only | Blank → Render | Full component | Poor |
| **SSR+Hydration** | Instant content | Event handlers only | Excellent |

## Data Attributes

Use `data-*` attributes to identify elements for hydration:

| Attribute | Purpose |
|-----------|---------|
| `data-accordion-item="id"` | Item container with unique ID |
| `data-accordion-trigger` | Clickable header button |
| `data-accordion-content` | Collapsible content area |
| `data-state="open\|closed"` | Current state for CSS styling |
| `data-arrow` | Arrow icon for rotation |
