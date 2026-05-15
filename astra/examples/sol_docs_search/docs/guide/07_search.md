---
title: Adding search
description: The full step-by-step for adding PageFind search to an existing Astra docs site.
---

<search-box></search-box>

# Adding search

This is the load-bearing page of the example: the exact recipe for adding PageFind to an existing Astra project.

## Step 1: install

```sh
pnpm add -D pagefind
```

The npm package ships prebuilt native binaries for the major platforms. There is no Rust toolchain step.

## Step 2: wire the post-build script

Edit `package.json`:

```json
{
  "scripts": {
    "build": "astra build && pagefind --site dist"
  }
}
```

The exact `astra build` invocation in this example points at the workspace-local build of the `astra` CLI rather than the published npm package, because this lives inside the `luna.mbt` monorepo:

```json
{
  "scripts": {
    "build:moon": "cd ../../.. && moon build --target js --release",
    "prebuild": "pnpm build:moon",
    "build": "node ../../../_build/js/release/build/mizchi/astra/cmd/astra/astra.js build && pagefind --site dist"
  }
}
```

For a standalone fork outside the monorepo, the simpler `astra build && pagefind --site dist` is enough.

## Step 3: write the Web Component

Drop `docs/public/islands/search-box.js`:

```js
class SearchBox extends HTMLElement {
  async connectedCallback() {
    const pagefind = await import("/pagefind/pagefind.js");
    await pagefind.init();
    this.innerHTML = `
      <input type="search" placeholder="Search">
      <div class="results"></div>
    `;
    this.querySelector("input").addEventListener("input", async (e) => {
      const search = await pagefind.search(e.target.value);
      const results = await Promise.all(
        search.results.slice(0, 5).map((r) => r.data()),
      );
      this.querySelector(".results").innerHTML = results
        .map((r) => `<a href="${r.url}">${r.meta.title}</a>`)
        .join("");
    });
  }
}
customElements.define("search-box", SearchBox);
```

The path `/pagefind/pagefind.js` is the default output location after `pagefind --site dist`. Change it only if you also passed `--output-subdir` to PageFind.

## Step 4: drop the element on any page

In any Markdown file:

```html
<search-box></search-box>
```

Astra auto-injects `<script type="module" src="/islands/search-box.js">` when it spots the matching tag in the rendered HTML, so no extra `<script>` line is needed.

## Step 5: build and serve

```sh
pnpm build
pnpm dlx http-server dist -p 5560
```

Visit `http://localhost:5560/` and type into the search box. You should see live results as you type.

## Debounce and ranking tweaks

The minimal implementation in this example fires a search on every keystroke. For larger sites, debounce by ~150 ms to avoid kicking off redundant work:

```js
let timer;
input.addEventListener("input", (e) => {
  clearTimeout(timer);
  timer = setTimeout(() => doSearch(e.target.value), 150);
});
```

PageFind ranks by BM25 with a length-normalisation factor. You can boost or filter results by adding `data-pagefind-weight="2"` to specific elements, or by passing `{ filters: {…}, sort: {…} }` to `search()`. See [PageFind's docs](https://pagefind.app/docs/) for the full API.
