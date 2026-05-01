# mizchi/astra

Mountable [Mars](https://mooncakes.io/docs/mizchi/mars/) middleware for
static-site generation in MoonBit. Renders Markdown / MDX documentation
pages on request and serves bundled assets (loader, default CSS, Shiki
syntax highlighting). Pair with the `astra` CLI to dump the same output
as a static tree (`astra build`) or serve it from a dev server
(`astra dev`).

```
deps: mars + markdown + luna       (no edge to sol)
```

## Install

```jsonc
// moon.mod.json
{
  "deps": {
    "mizchi/astra": "0.1.0",
    "mizchi/mars": "0.3.10",
    "mizchi/luna": "0.18.3"
  }
}
```

## Quick start — mount on a Mars server

```moonbit
import "mizchi/astra/middleware" as middleware
import "mizchi/mars" as mars

async fn main {
  let cfg = @astra.SsgConfig::default()
  let mw  = @middleware.create(cfg, cwd=".")
  let app = @mars.Server::new()
  app.all("/*", mw.handler())
  app.listen(port=3000)
}
```

`Middleware::handler()` returns a Mars `Handler` that responds to GET on
every page URL the document tree exposes plus the asset URLs in
`@assets.list_asset_urls()`. `Middleware::list_urls()` returns the union,
which the build CLI uses to crawl.

## Quick start — CLI

```bash
# Dev server against the current directory's docs/ tree
astra dev --port 3000

# Static dump (writes <out>/<url>/index.html for every page URL)
astra build --out ./dist
```

A working example lives at
[`astra/examples/sol_docs/`](./examples/sol_docs/) — a docs site with
i18n, blog, MDX, components, and parity tests against the sol-built
output.

## How dev and build share one Middleware

Both modes go through the same `Middleware::handler()`. The build crawler
calls `@testing.invoke(handler, path=url)` for each entry in
`mw.list_urls()` and writes the response body to disk. So if a page
renders correctly via `astra dev`, it is also correct in the static
dump — there is no second renderer to keep in sync.

## Configuration

`astra.config.json` (or `sol.config.json` for back-compat) drives:

- `docs_dir` — where to scan markdown sources (default `docs`)
- `output_dir` — where `astra build` writes (default `dist`)
- `theme` — colors, fonts, header/footer/sidebar variants
- `i18n` — locales and routing
- `islands` — JSX/TSX hydration components
- `meta_files` — sitemap, robots, OGP defaults

The full schema is `@astra.SsgConfig`; `astra/docs/parity-notes.md` lists
fields the static-build path honors that the middleware path does not yet.

## Known parity gaps with sol's pre-extraction SSG

`astra/docs/parity-notes.md` lists every place the middleware-served
output diverges from a `copy_static_assets`-style static build (utility
CSS extraction, sitemap generation, Cloudflare adapter manifests, etc.).
None affect the rendered HTML body of pages today; closing the
remaining gaps is tracked there.

## License

MIT
