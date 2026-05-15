# mizchi/astra

Static site generator in MoonBit. Renders Markdown / MDX documentation
pages and bundles the assets needed to display them (loader, default
CSS, Shiki syntax highlighting). The default workflow is `astra build`
→ static tree → any CDN; `astra dev` runs a local preview server.

Internally astra is implemented as [Mars](https://mooncakes.io/docs/mizchi/mars/)
middleware so the same renderer can also be mounted on a long-running
Mars server (for sol embedding or ISR-style on-demand revalidation),
but that path is **optional** — `astra build` does not open a network
listener and the build output is fully deployable as a static bundle.

```
deps: mars + markdown + luna       (no edge to sol)
```

## Install

Library:

```jsonc
// moon.mod.json
{
  "deps": {
    "mizchi/astra": "0.20.0",
    "mizchi/mars": "0.3.10",
    "mizchi/luna": "0.20.0"
  }
}
```

CLI (binary):

```sh
moon install mizchi/astra/cmd/astra  # → $MOON_HOME/bin/astra
# or via npm
pnpm add -g @luna_ui/astra           # 0.20.0
```

## Quick start — CLI (default path)

```bash
# Static dump (writes <out>/<url>/index.html for every page URL)
astra build --out ./dist

# Dev server against the current directory's docs/ tree
astra dev --port 3000
```

`astra build` walks every URL the in-process middleware can serve and
writes the rendered body to `<out>/<url-to-disk-path>`. No network
listener is opened during the build — dispatch goes through the
testing harness (`@testing.invoke`). Deploy the resulting tree to any
static host (Cloudflare Workers Static Assets, GitHub Pages, S3, etc).

A working example lives at
[`astra/examples/sol_docs/`](./examples/sol_docs/) — a docs site with
i18n, blog, MDX, components, and parity tests against the sol-built
output.

## Optional — mount on a Mars server

Reach for this only when you need on-demand rendering inside a
long-running server (sol embedding, ISR with `revalidate`, dynamic
content). For a pure docs / blog site the static path above is enough.

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

## How dev and build share one Middleware

Both modes go through the same `Middleware::handler()`. The build crawler
calls `@testing.invoke(handler, path=url)` for each entry in
`mw.list_urls()` and writes the response body to disk. So if a page
renders correctly via `astra dev`, it is also correct in the static
dump — there is no second renderer to keep in sync.

## Configuration

`astra.config.json` is the primary config file. `sol.config.json` is
read as a fallback when `astra.config.json` is missing (kept for
compatibility with projects that started under sol's SSG mode before
astra extraction). New projects should write `astra.config.json`.

The config drives:

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
