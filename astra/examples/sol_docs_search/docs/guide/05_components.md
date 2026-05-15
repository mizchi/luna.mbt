---
title: Components and islands
description: Adding interactive bits with Web Components, TSX, or MoonBit-rendered fragments.
---

<search-box></search-box>

# Components and islands

Astra supports three ways to drop dynamic content into an otherwise-static page. They are listed roughly in increasing order of complexity.

## 1. Web Components (the islands directory)

Anything under `docs/public/islands/*.js` is bundled by rolldown and emitted to `dist/islands/`. The HTML you write in Markdown references the custom element by its tag name:

```html
<search-box></search-box>
```

There is no per-page config or hydration boundary to declare. The Web Component upgrades itself once the browser sees `<script type="module" src="/islands/search-box.js">` — which Astra injects automatically when it detects a matching tag in the page.

This is the cheapest option. It does not require importing the Luna runtime, does not need signals, and does not need a build step beyond rolldown's tree-shaking. PageFind's UI is itself a Web Component when used as `<div id="search"><script src="/pagefind/pagefind-ui.js">…`, so this style composes naturally with PageFind.

## 2. TSX components rendered to HTML

For larger components, you can write a TSX file under `app/components/` and reference it from a route handler. The component renders to a string at build time via React's `renderToString`, and the resulting HTML is interpolated into the page. There is no client-side React runtime — the output is plain HTML.

This is the right choice for components that need conditional rendering based on the page's frontmatter (e.g. an author byline that pulls from `frontmatter.author`).

## 3. MoonBit components via Luna's stream renderer

If you are already in the MoonBit world, you can write a component as:

```moonbit
pub fn render() -> @luna.Node[Unit] {
  @luna.div([
    @luna.text("Hello from MoonBit"),
  ])
}
```

This integrates with the Luna VDOM, supports signals, and runs through `renderToStream` for partial-page streaming when serving from the Mars mount. In pure SSG mode it falls back to a synchronous string render.

## Picking a strategy

- For a docs site that needs a search box, a code-copy button, a theme toggle, or a small interactive demo, **Web Components** are almost always the right answer. They keep the build small and avoid any framework lock-in.
- For components that depend on frontmatter or other build-time data, **TSX** is the easier fit.
- For shared rendering with the rest of a Luna-based application, **MoonBit components** keep everything in one language.

This example uses option 1 — the `<search-box>` Web Component is the only client-side code in the entire project.
