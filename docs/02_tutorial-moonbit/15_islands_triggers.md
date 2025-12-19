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

```moonbit
///|
using @server_dom { island }
using @luna { Load }

island(
  id="search",
  url="/static/search.js",
  trigger=Load,  // Hydrate immediately
  children=[...],
)
```

```html
<div luna:id="search" luna:client-trigger="load">...</div>
```

**Use for:**
- Header search boxes
- Navigation menus
- Critical interactive elements
- Above-the-fold content

## Idle Trigger

Hydrate when the browser is idle (using `requestIdleCallback`):

```moonbit
///|
using @server_dom { island }
using @luna { Idle }

island(
  id="analytics",
  url="/static/analytics.js",
  trigger=Idle,  // Hydrate when browser is idle
  children=[...],
)
```

```html
<div luna:id="analytics" luna:client-trigger="idle">...</div>
```

**Use for:**
- Analytics tracking
- Non-essential widgets
- Background features
- Low-priority interactions

## Visible Trigger

Hydrate when the element scrolls into view (using `IntersectionObserver`):

```moonbit
///|
using @server_dom { island }
using @luna { Visible }

island(
  id="comments",
  url="/static/comments.js",
  trigger=Visible,  // Hydrate when scrolled to
  children=[...],
)
```

```html
<div luna:id="comments" luna:client-trigger="visible">...</div>
```

**Use for:**
- Comments sections
- Image galleries
- Infinite scroll
- Footer widgets
- Any below-fold content

## Media Trigger

Hydrate when a media query matches:

```moonbit
///|
using @server_dom { island }
using @luna { Media }

island(
  id="sidebar",
  url="/static/sidebar.js",
  trigger=Media("(min-width: 768px)"),  // Desktop only
  children=[...],
)
```

```html
<div luna:id="sidebar" luna:client-trigger="media:(min-width: 768px)">...</div>
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

```moonbit
///|
using @server_dom { div, type Node }
using @luna { Load, Idle, Visible, Media }

fn blog_page() -> Node {
  div([
    // Immediate - critical for UX
    search_island(trigger=Load),

    // Idle - nice to have but not urgent
    theme_toggle_island(trigger=Idle),

    // Static article content - no JS
    article_content(),

    // Visible - only load when user scrolls down
    comments_island(trigger=Visible),

    // Media - only on desktop
    sidebar_widget(trigger=Media("(min-width: 1024px)")),
  ])
}
```

## Manual Trigger (None)

For programmatic control, use `none`:

```moonbit
///|
using @server_dom { island }
using @luna { None }

island(
  id="modal",
  url="/static/modal.js",
  trigger=None,  // Manual hydration
  children=[...],
)
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
