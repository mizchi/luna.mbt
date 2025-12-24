---
title: "Islands: Triggers"
---

# Hydration Triggers

Control exactly when your islands become interactive.

## Available Triggers

Luna provides four hydration triggers:

| Trigger | When | Use Case |
|---------|------|----------|
| `load` | Immediately on page load | Critical UI, above-fold content |
| `idle` | When browser is idle | Non-critical features |
| `visible` | When element enters viewport | Below-fold content |
| `media` | When media query matches | Responsive features |

## Load Trigger

Hydrate immediately when the page loads:

```html
<div luna:id="search" luna:url="/static/search.js" luna:client-trigger="load">
  <!-- Server-rendered content -->
</div>
```

**Use for:**
- Header search boxes
- Navigation menus
- Critical interactive elements
- Above-the-fold content

## Idle Trigger

Hydrate when the browser is idle (using `requestIdleCallback`):

```html
<div luna:id="analytics" luna:url="/static/analytics.js" luna:client-trigger="idle">
  <!-- Server-rendered content -->
</div>
```

**Use for:**
- Analytics tracking
- Non-essential widgets
- Background features
- Low-priority interactions

## Visible Trigger

Hydrate when the element scrolls into view (using `IntersectionObserver`):

```html
<div luna:id="comments" luna:url="/static/comments.js" luna:client-trigger="visible">
  <!-- Server-rendered content -->
</div>
```

**Use for:**
- Comments sections
- Image galleries
- Infinite scroll
- Footer widgets
- Any below-fold content

## Media Trigger

Hydrate when a media query matches:

```html
<div luna:id="sidebar" luna:url="/static/sidebar.js" luna:client-trigger="media:(min-width: 768px)">
  <!-- Server-rendered content -->
</div>
```

**Use for:**
- Desktop-only features
- Mobile-specific components
- Responsive interactions
- Orientation-dependent UI

### Media Query Examples

```html
<!-- Desktop only (768px+) -->
<div luna:client-trigger="media:(min-width: 768px)">...</div>

<!-- Mobile only (under 768px) -->
<div luna:client-trigger="media:(max-width: 767px)">...</div>

<!-- Dark mode preference -->
<div luna:client-trigger="media:(prefers-color-scheme: dark)">...</div>

<!-- Reduced motion preference -->
<div luna:client-trigger="media:(prefers-reduced-motion: no-preference)">...</div>

<!-- Landscape orientation -->
<div luna:client-trigger="media:(orientation: landscape)">...</div>
```

## Choosing the Right Trigger

### Decision Flow

```
Is it above the fold?
├── Yes → Is it critical for initial interaction?
│         ├── Yes → load
│         └── No → idle
└── No → Will users always scroll to it?
          ├── Yes → visible
          └── No → Is it device-specific?
                    ├── Yes → media
                    └── No → visible or idle
```

### Performance Impact

| Trigger | Initial Load | LCP Impact | TTI Impact |
|---------|--------------|------------|------------|
| `load` | Heavy | None | Delayed |
| `idle` | Light | None | Minimal |
| `visible` | None | None | None |
| `media` | Conditional | None | Minimal |

## Combining Strategies

A typical page might use all triggers:

```html
<div>
  <!-- Immediate - critical for UX -->
  <div luna:id="search" luna:client-trigger="load">...</div>

  <!-- Idle - nice to have but not urgent -->
  <div luna:id="theme-toggle" luna:client-trigger="idle">...</div>

  <!-- Static article content - no JS -->
  <article>...</article>

  <!-- Visible - only load when user scrolls down -->
  <div luna:id="comments" luna:client-trigger="visible">...</div>

  <!-- Media - only on desktop -->
  <div luna:id="sidebar" luna:client-trigger="media:(min-width: 1024px)">...</div>
</div>
```

> For server-side rendering with MoonBit, see the [MoonBit Tutorial](/luna/tutorial-moonbit/).

## Manual Trigger (None)

For programmatic control, use `none`:

```html
<div luna:id="modal" luna:url="/static/modal.js" luna:client-trigger="none">
  <!-- Server-rendered modal content -->
</div>
```

Then trigger from JavaScript:

```typescript
// Hydrate manually when needed
window.__LUNA_HYDRATE__?.("modal");
```

**Use for:**
- Modals opened by user action
- Lazy-loaded features
- On-demand functionality

## Monitoring Hydration

Track hydration timing:

```typescript
// In your island component
hydrate("myComponent", (props) => {
  console.log("Hydrated at:", performance.now());
  return <MyComponent {...props} />;
});
```

## Try It

Assign triggers to these components:

1. Site-wide search box
2. Cookie consent banner
3. Image lightbox
4. Live chat widget
5. Mobile hamburger menu

<details>
<summary>Suggested Answers</summary>

1. **Search box** → `load` (critical, above fold)
2. **Cookie consent** → `idle` (not critical, can wait)
3. **Image lightbox** → `visible` or `none` (only when viewing images)
4. **Live chat** → `idle` (background feature)
5. **Mobile menu** → `media:(max-width: 767px)` (mobile only)

</details>

## Next

Learn about [Server-to-Client State →](./islands_state)
