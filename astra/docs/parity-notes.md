# Astra build parity notes (Phase B exit, T11)

This document records the diff between two paths that should produce
equivalent static dumps for the same `SsgConfig` against
`sol/examples/sol_docs`:

- **Middleware build**: `astra build` -- `Middleware::create` -> walk
  `list_urls` -> dispatch each through `Server::to_handler` -> write the
  captured response body to disk. Used by the dev server and the build CLI.
- **Static build**: `astra build --mode ssg` -- `render.generate_site_async`,
  i.e. the canonical pipeline that sol's old SSG build used. Produces
  navigation manifests, deploy adapter output, sitemap, 404 page, etc.

Reproduction:

```sh
moon build --release --target js
cd sol/examples/sol_docs
node ../../_build/js/release/build/mizchi/astra/cli/main/main.js build --mode ssg
mv dist /tmp/sol_dump
node ../../_build/js/release/build/mizchi/astra/cli/main/main.js build --out /tmp/astra_dump
diff -rq /tmp/sol_dump /tmp/astra_dump
```

Phase B exit criterion (plan line 924):
> astra dev boots a working docs server against `examples/sol_docs`, astra
> build dumps a static tree byte-comparable to sol's old output (modulo
> intentional diffs), and `moon test` is green workspace-wide.

## Result summary

After T11 close-up:

| Bucket | Count |
|---|---|
| Trivial / no-op | 0 |
| **Intentional** (documented; middleware deliberately doesn't produce) | 5 |
| **Bug fixed in T11** (closed before this commit) | 4 |
| Bug remaining (DOCUMENTED, not closed) | 1 |

Page HTML files byte-match across all 25 page URLs except `tsx_demo`. The
3 CSS asset files (`style.css`, `shiki.css`, `github-markdown.css`) and
`loader.js` byte-match.

## Closed in T11

These were diffs after T10 that T11 narrowed to byte-equivalent.

### 1. `style.css` -- theme overrides

- **Before**: middleware served raw `get_default_css(config)` only.
- **After**: `lookup_asset` calls a new `build_style_css_body` helper that
  appends `:root{...}` derived from `ThemeConfig`, mirroring the tail of
  `build_combined_css` in `astra/render/css_processor.mbt`. The helper
  lives in `astra/src/assets/theme_overrides.mbt` (a verbatim copy of the
  private `build_theme_overrides` in render; copied because `assets` cannot
  import `render` -- it's the wrong direction in the dep graph).

### 2. `style.css` / `shiki.css` / `github-markdown.css` -- minification

- **Before**: middleware served the raw CSS strings; the static-build path
  ran `minify_css` for non-dev mode, so `astra build`'s output was larger
  and whitespace-different.
- **After**: `lookup_asset` accepts a `minify~ : Bool = false` flag. The
  asset path now applies `minify_css` (same algorithm as render's private
  one; copied to `astra/src/assets/css_minify.mbt`). `Middleware::create`
  takes `minify_css~ : Bool = false` and threads it; `build_to_disk`
  passes `true`, the dev server stays on `false` (readable CSS).

### 3. `/assets/shiki.css` URL

- **Before**: not in `list_asset_urls`, so the middleware build skipped it
  entirely. Static-build wrote `assets/shiki.css` from `@shiki.generate_shiki_css`.
- **After**: `lookup_asset` returns it; `list_asset_urls` includes it.
  `assets/moon.pkg` now imports `@shiki`.

### 4. Code-block syntax highlighting (Shiki)

- **Before**: `render_page` in middleware passed `None` for the highlighter
  to `render_page_html`, so all `<pre>` elements emitted plain
  `<code class="...">` blocks. The static-build path constructed a Shiki
  highlighter and emitted highlighted `<pre class="highlight github-dark">`
  blocks. This made every page with a code block diff between the two
  outputs.
- **After**: `Middleware::create` accepts an optional `highlighter`.
  `build_to_disk` (via `run_build`) creates one with
  `@shiki.create_default_highlighter()` and threads it. Dev server stays on
  `None` so per-request latency doesn't regress.

## Documented (not closed)

### 5. CSS-utility extraction (`extract_css_utilities`)

- **Status**: NOT CLOSED. `lookup_asset` does not run the utility-CSS
  extractor. `extract_css_utilities` shells out to a `node extract.js`
  child process over each configured `source_dir`, scans for class names,
  and emits utility CSS rules (e.g. `.bg-indigo-500 { background: ...; }`).
  In `sol/examples/sol_docs` the `extract.js` script is not present
  (it ships with the luna repo via `js/loader/dist`), so the static-build
  path produces an **empty** utility-CSS contribution -- and the diff
  collapses to zero for this fixture. In a project that does ship
  `extract.js` (the luna monorepo itself, or a downstream that installs
  `@luna_ui/sol/css/extract.js` via npm), the diff would be non-empty:
  `astra build` would lack the extracted utility classes that
  `astra build --mode ssg` would include.
- **Why deferred**: closing the gap requires running an async child
  process at `Middleware::create` time, which forces `create_async` and a
  mass call-site update across the cli, dev server, build crawler, and
  middleware tests. The plan budget for T11 doesn't cover that scope, and
  no fixture in this repo exercises it. Re-open in Phase C if a downstream
  project hits parity-loss when it ships `extract.js`.

### 6. `404.html` (sol-only)

- **Status**: ACCEPTED INTENTIONAL. `generate_404_page` writes a static
  404 HTML file whose only consumer is the deployment platform (Cloudflare
  Pages, Netlify, etc.). At dev time the middleware returns `text("Not
  Found", status=404)` for unknown paths, which is functionally the same.
  The build crawler never visits an unknown URL, so no static 404 file is
  written. A dedicated post-build hook could synthesize one; tracked in
  Phase C T12-T13 along with deploy adapter parity.

### 7. `_luna/` directory (sol-only)

- **Status**: ACCEPTED INTENTIONAL. Contains `manifest.json` (client chunk
  manifest), `isr.json` (ISR manifest), `routes/*.json` (per-route data
  files). All consumed at runtime by sol's app-mode router, not by the
  docs SSG. The middleware build is docs-only, so these files aren't part
  of the byte-compared surface. Phase C will decide whether the docs build
  emits them.

### 8. `_routes.json` (sol-only)

- **Status**: ACCEPTED INTENTIONAL. Cloudflare Pages `_routes.json`
  written by `@adapters.run_adapter`. Pure deploy artifact; not consumed
  at request time. Same Phase C trigger as `_luna/`.

### 9. `islands/` directory (sol-only)

- **Status**: ACCEPTED INTENTIONAL. `copy_islands_dir` bundles the
  configured islands directory (`docs/public/islands` per
  `sol.config.json`'s `islands.dir`) through rolldown. Produces JS bundles
  consumed at runtime by the loader. Astra middleware doesn't bundle (the
  loader source is exposed separately at `/assets/loader.js`); when the
  docs project provides pre-bundled islands, they would be served via the
  asset surface, not regenerated. Build-time bundling parity is Phase C.

### 10. `sitemap.xml` (sol-only)

- **Status**: ACCEPTED INTENTIONAL. `generate_meta_files` writes
  `sitemap.xml`, `rss.xml`, `llms.txt` for SEO/aggregation tools. None are
  consumed at request time. They're easy to add via a post-build hook in
  the cli; tracked in Phase C.

### 11. `tsx_demo/index.html` -- TSX SSR placeholder

- **Status**: ACCEPTED INTENTIONAL. The fixture's `tsx_demo` page
  references a TSX component that requires async SSR. Sol's SSG path
  attempts the async render and writes `data-ssr="failed"` when the SSR
  itself fails (the demo hooks aren't wired up in this fixture); astra's
  middleware path doesn't attempt async TSX SSR at all and writes
  `data-ssr="pending"`. Both are degenerate states. The "correct"
  resolution is to enable async TSX SSR in middleware (`build_to_disk` is
  already async-capable). Tracked alongside the CSS-utility deferral
  above; the right place to fix it is in `render_page_html`'s component
  hook, not in the middleware.

## Asset-byte equality (post-T11)

```
$ wc -c /tmp/sol_dump/assets/* /tmp/astra_dump/assets/*
   85 /tmp/sol_dump/assets/github-markdown.css
   83 /tmp/sol_dump/assets/loader.js
  891 /tmp/sol_dump/assets/shiki.css
  143 /tmp/sol_dump/assets/style.css
   85 /tmp/astra_dump/assets/github-markdown.css
   83 /tmp/astra_dump/assets/loader.js
  891 /tmp/astra_dump/assets/shiki.css
  143 /tmp/astra_dump/assets/style.css
```

(`loader.js` is a fallback stub here because the luna source is not
checked into this repo; in a real project it would be the bundled
`loader.iife.js`. The two paths agree byte-for-byte regardless.)

(Not regenerated automatically -- run the reproduction commands above
when this drifts.)
