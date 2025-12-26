---
title: Islands
description: Embed interactive Luna components in static pages
---

# Islands Architecture

Islands allow you to embed interactive Luna (MoonBit) components within static pages. The page is rendered as static HTML, and specific interactive regions ("islands") are hydrated on the client.

## Overview

```
┌─────────────────────────────────────┐
│  Static HTML (SSG)                  │
│  ┌─────────────────────────────┐    │
│  │  Island (Interactive)       │    │
│  │  - Luna/MoonBit component   │    │
│  │  - Hydrated on client       │    │
│  └─────────────────────────────┘    │
│  More static content...             │
└─────────────────────────────────────┘
```

## Configuration

### 1. astra.json

Configure the islands directory:

```json
{
  "islands": {
    "dir": "docs/public/islands",
    "basePath": "/islands/"
  }
}
```

### 2. Build the Component

Create a MoonBit component with a `hydrate` export:

```moonbit
// src/examples/wiki/main.mbt
pub fn hydrate(el : @js_dom.Element, _state : @js.Any) -> Unit {
  // Initialize your component
  let container = el |> @dom.DomElement::from_jsdom
  // ... render logic
}
```

Package configuration (`moon.pkg.json`):

```json
{
  "is-main": true,
  "supported-targets": ["js"],
  "import": [
    "mizchi/luna/luna/signal",
    { "path": "mizchi/luna/platform/dom/element", "alias": "dom" },
    { "path": "mizchi/js/browser/dom", "alias": "js_dom" },
    { "path": "mizchi/js/core", "alias": "js" }
  ],
  "link": {
    "js": {
      "format": "esm",
      "exports": ["hydrate"]
    }
  }
}
```

### 3. Copy to Islands Directory

After building, copy the compiled JS to the islands directory:

```bash
moon build --target js
cp target/js/release/build/examples/wiki/wiki.js docs/public/islands/
```

### 4. Use in Markdown

Reference the island in your markdown:

```markdown
---
title: Wiki
islands:
  - wiki
---

# Wiki Demo

<Island name="wiki" trigger="load" />
```

## Island Directive Syntax

```html
<Island name="component-name" trigger="load" />
```

### Attributes

| Attribute | Description |
|-----------|-------------|
| `name` | Component name (matches filename without .js) |
| `trigger` | Hydration trigger (see below) |

### Trigger Types

| Trigger | Description |
|---------|-------------|
| `load` | Hydrate immediately on page load |
| `idle` | Hydrate when browser is idle |
| `visible` | Hydrate when element enters viewport |

## Client-Side Routing with BrowserRouter

Islands can implement full client-side routing using Luna's BrowserRouter:

```moonbit
fn create_routes() -> Array[@routes.Routes] {
  [
    Page(path="", component="home", title="Home", meta=[]),
    Page(path="/:slug", component="page", title="Page", meta=[]),
  ]
}

pub fn hydrate(el : @js_dom.Element, _state : @js.Any) -> Unit {
  let base = "/wiki"
  let routes = create_routes()
  let router = @router.BrowserRouter::new(routes, base~)

  let container = el |> @dom.DomElement::from_jsdom
  render_app(router, container)
}
```

This enables:
- Client-side navigation without page reload
- Dynamic URL parameters (`:slug`)
- Browser history (back/forward) support

## Generated HTML

The Island directive generates:

```html
<!--luna:island:wiki url=/islands/wiki.js trigger=load-->
<div luna:id="wiki"
     luna:url="/islands/wiki.js"
     luna:state="{}"
     luna:client-trigger="load">
</div>
<!--/luna:island:wiki-->
```

The Luna loader automatically discovers and hydrates these elements.

## Example: Wiki with Dynamic Routing

See `examples/astra_app/docs/wiki/` for a complete example:

1. **Static entry**: `/wiki/` - Single HTML page with island placeholder
2. **Client routing**: BrowserRouter handles `/wiki/:slug` patterns
3. **No server needed**: Fully static, works with any file server

```
/wiki/                    → Wiki Home (index page)
/wiki/getting-started     → Handled by BrowserRouter
/wiki/configuration       → Handled by BrowserRouter
```

## Islands vs Dynamic Routes

| Use Case | Solution |
|----------|----------|
| Blog posts (SEO important) | Dynamic Routes (`_slug_`) |
| Interactive documentation | Islands |
| SPA within static site | Islands + BrowserRouter |
| Static content pages | Regular Markdown |
