---
title: PageFind internals
description: What PageFind actually emits, how the index is structured, and how the client API works.
---

<search-box></search-box>

# PageFind internals

This page is not strictly required reading, but it helps when debugging why search results look the way they do, or when planning a custom UI.

## What PageFind emits

After `pagefind --site dist`, you have:

```
dist/pagefind/
├── pagefind.js              # entry bundle (~5 KB, gzip)
├── pagefind-modular-ui.js   # optional pre-styled UI
├── pagefind-ui.css          # CSS for the pre-styled UI
├── pagefind-highlight.js    # optional in-page highlight script
├── wasm.[lang].pagefind     # per-language WASM blob
├── index/
│   └── [lang]/[shard].pf_index
└── fragment/
    └── [lang]_[hash].pf_fragment
```

The split is deliberate:

- **`index/`** shards contain inverted index data — which tokens appear in which page.
- **`fragment/`** shards contain the actual snippets to surface to the user. They are lazy-loaded only when a result is shown.

The browser fetches one or two `pf_index` shards per query, and then (only for the displayed hits) the matching `pf_fragment`. Typical bytes-over-wire for a 200-page site:

- Cold first query: ~150 KB (`pagefind.js` + one WASM blob + one index shard).
- Subsequent queries: 20-40 KB (one more index shard + 5 fragments).

This is why PageFind scales reasonably to a few thousand pages without server-side help.

## The JS API

```js
import * as pagefind from "/pagefind/pagefind.js";

// Optional: ensure WASM is preloaded before first search.
await pagefind.init();

const result = await pagefind.search("hydration");
console.log(result.results.length); // total matches
const top = await Promise.all(
  result.results.slice(0, 5).map((r) => r.data()),
);
// top[i] = { url, meta: { title, ... }, excerpt, content, ... }
```

The `result.results` array is lazy — calling `.data()` is what triggers the fragment fetch. This means you can paginate or render only the top N without paying for the rest.

### Filters

```js
const r = await pagefind.search("hydration", {
  filters: { section: ["guide"] },
});
```

A "filter" is any element in the page tagged with `data-pagefind-filter="section:guide"`. The value `section` is the filter name; `guide` is the bucket. Multiple filters on the same name OR together; different names AND together.

### Sort

```js
const r = await pagefind.search("hydration", {
  sort: { date: "desc" },
});
```

Sort keys come from `data-pagefind-sort="date:2026-05-15"` in the page. Without an explicit sort, results come back by BM25 relevance.

## When to skip the bundled UI

PageFind ships an optional `pagefind-ui.js` that renders a styled search modal. It's perfectly fine for many sites. We don't use it here because:

- It pulls in its own CSS, which conflicts with custom theming.
- The bundle size is larger (~30 KB vs ~5 KB for `pagefind.js`).
- A 30-line Web Component is enough for the common case.

For projects that need the modal experience (keyboard shortcuts, recent searches, highlight-in-page), the bundled UI is the right answer. For everything else, calling the API directly from a Web Component keeps the surface area small.
