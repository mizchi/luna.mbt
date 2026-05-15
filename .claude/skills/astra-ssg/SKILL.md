---
name: astra-ssg
description: Use when building markdown-driven docs / blog sites with `mizchi/astra`. Astra is a static-site generator first — `astra build` writes a pure-static tree to disk and `astra dev` runs a local preview server. The Mars-middleware form (`mizchi/astra/middleware`) is a secondary shape for when you need to mount the same content on a long-running server (e.g. sol). `astra build` itself does not open a network listener — it dispatches every URL in-process via the testing harness — so the typical deploy is "build once, serve from any static host" (CF Workers Static Assets, GitHub Pages, S3, etc.). Covers (a) the file-to-URL routing rules under `docs/` (every `.md` becomes a route; `index.md` becomes the directory root; `ja/` and other locale dirs are i18n branches), (b) `astra.config.json` fields (`docs_dir`, `out_dir`, `nav`, `sidebar`, `i18n`, `islands`, `spaRoutes`, `deploy`, `headSnippets`), (c) per-page metadata via frontmatter (`title`, `description`, `layout`, `sidebar`, `revalidate` for ISR — the last one only matters when served from Mars) and `page.json` (`ssr`, `renderer`, `spa`, `fallbackBehavior`, `staticParams`), (d) three ways to drop components onto a page — TSX with React `renderToString` SSR, MoonBit `.mbt` with `pub fn render() -> Node[Unit]`, or client-side web components in the islands directory, (e) when to reach for the middleware mount instead (sol embedding, on-demand revalidation), and (f) how this composes with sol (no edge: astra has no sol dependency).
---

# astra-ssg

## Purpose

`mizchi/astra` is a markdown-driven **static site generator** in MoonBit. The primary form is the CLI:

- `astra build` walks the configured `docs_dir`, renders every URL through an in-process handler, and writes a pure-static tree to `out_dir/` (default `dist/`). **No network listener is opened during the build** — dispatch happens via the testing harness (`@testing.invoke`), as documented in `astra/src/cli/build.mbt`'s header comment ("no localhost listener"). The result is a CDN-friendly bundle that any static host can serve: Cloudflare Workers Static Assets, GitHub Pages, S3 + CloudFront, Vercel/Netlify static, etc.
- `astra dev` does open a `node:http` listener for local preview, but only because that's what a dev server needs. Build-and-deploy paths never depend on a running process.

The Mars-middleware form (`mizchi/astra/middleware`) is a **secondary shape** for when you specifically want to mount the same content on a long-running server — typically when embedding astra inside a sol app or running ISR-style revalidation. Reaching for the middleware is opt-in; the SSG path does not require Mars to be present at runtime.

Astra has **no dependency on sol** (`deps: mars + markdown + luna`). It was extracted out of sol's old SSG mode in 0.16.0. If you see `sol new --doc` in older notes, it has been removed — use astra directly.

## When to use

- Building or maintaining a docs / blog site in this repo (`website/` is one such site)
- Adding new markdown pages, navigation entries, or sidebar configuration
- Adding interactive components (TSX, MoonBit, or web components) into otherwise-static pages
- Auditing `astra.config.json` against the field list below
- Choosing between the default SSG path (`astra build` → static host) and the middleware mount (sol embedding / ISR with `revalidate`)

## When to reach for the Mars middleware mount instead

Default to `astra build` + static hosting. Switch to mounting `@middleware.create(...)` on a Mars `Server` only when one of these applies:

- You need to serve astra-rendered pages from inside an existing long-running server (sol app, custom Mars worker) and don't want a separate static origin.
- A page genuinely needs on-request rendering — e.g. `revalidate: 300` ISR semantics, dynamic content that can't be enumerated at build time, request-driven personalization.
- You want to compose astra under a non-`/` base path of a running app whose other routes are dynamic.

For a pure docs / blog site, none of these apply — `astra build` and a CDN are the right answer.

## File-to-URL routing

Astra scans `docs_dir` (default `docs/`) recursively and turns every `.md` file into a route:

| File | URL |
|------|-----|
| `docs/index.md` | `/` |
| `docs/guide/index.md` | `/guide/` |
| `docs/guide/config.md` | `/guide/config` (or `/guide/config/` if `trailing_slash: true`) |
| `docs/blog/post-1.md` | `/blog/post-1` |
| `docs/ja/index.md` | `/ja/` (= the `ja` locale's home, see i18n section) |
| `docs/ja/guide/config.md` | `/ja/guide/config` |
| `docs/[slug]/page.md` (dynamic) | template route — populate with `staticParams` in `page.json` |

The `trailing_slash` config controls whether routes end with `/`. The default is `false` for `astra` defaults but `true` in the `sol_docs` example and in `website/`.

Excluded paths come from `astra.config.json::exclude` — e.g. `["internal", "dist-docs"]` skips those subtrees.

## `astra.config.json` fields

`astra.config.json` is the canonical config name. `sol.config.json` is read only as a fallback when `astra.config.json` is missing (legacy compatibility — `astra/src/cli/cli.mbt` is the resolution source of truth).

```json
{
  "$schema": "../path/to/schemas/sol.config.schema.json",
  "title": "My Site",
  "description": "Site description",
  "docs_dir": "docs",
  "out_dir": "dist",
  "base_url": "/",
  "trailing_slash": true,
  "exclude": ["internal", "tmp"],
  "deploy": "cloudflare",

  "nav": [
    { "text": "Guide", "link": "/guide/" },
    { "text": "GitHub", "link": "https://github.com/owner/repo", "icon": "github" }
  ],
  "sidebar": "auto",

  "i18n": {
    "defaultLocale": "en",
    "locales": [
      { "code": "en", "label": "English", "path": "" },
      { "code": "ja", "label": "日本語", "path": "ja" }
    ]
  },

  "islands": {
    "dir": "components",
    "basePath": "/components/"
  },
  "spaRoutes": ["/wiki/"],
  "headSnippets": ["<style>...</style>"],

  "navigation": {
    "spa": true,
    "viewTransitions": false,
    "keyboard": true
  },

  "theme": {
    "socialLinks": [{ "icon": "github", "link": "https://github.com/..." }],
    "footer": { "...": "..." }
  }
}
```

Key fields:

| Field | Purpose |
|-------|---------|
| `title` / `description` | site-wide metadata, also used as default `<title>` / meta |
| `docs_dir` / `out_dir` | source / output roots (defaults: `docs` / `dist`) |
| `base_url` | URL prefix when the site is served under a subpath |
| `trailing_slash` | whether routes end with `/` |
| `exclude` | subdirs of `docs_dir` to skip |
| `nav` | top navbar entries (text + link + optional icon) |
| `sidebar` | `"auto"` (folder tree → sidebar) or manual array (see `astra/docs/guide/configuration.md`) |
| `i18n.defaultLocale` / `i18n.locales` | language switcher, locale-path mapping |
| `islands.dir` / `islands.basePath` | where client-side islands live; `rolldown` bundles them when `astra build` runs |
| `spaRoutes` | routes that are SPA-navigated rather than full-page reloads |
| `headSnippets` | additional `<head>` content injected on every page |
| `deploy` | adapter hint (`"cloudflare"` etc.) — surfaces in `astra build` and CI templates |

## Per-page metadata

Two parallel mechanisms, both optional:

### Frontmatter (in the `.md` file itself)

```markdown
---
title: My Page Title
description: Page description for <meta>
layout: doc          # or "home", "default"
sidebar: true        # show the sidebar on this page (default: true)
revalidate: 300      # ISR TTL in seconds (only meaningful when served from Mars)
---

# Heading
```

### `page.json` (alongside the `.md` in the same directory)

Used for settings that don't belong in markdown frontmatter, or for component-only routes:

```json
{
  "title": "TSX Demo",
  "description": "Demo of TSX SSR",
  "ssr": true,                 // server-render this page (vs. SSG)
  "renderer": "react",         // renderer for TSX components on this page
  "spa": true,                 // page belongs to an SPA-navigated region
  "fallbackBehavior": "spa",   // SPA fallback on 404
  "staticParams": [            // for dynamic routes: enumerate the slug values
    { "slug": "hello-world" },
    { "slug": "getting-started" }
  ]
}
```

`page.json` wins over frontmatter for keys that appear in both.

## Components on a page

Three ways to add interactive content, pick by use case:

### 1. TSX (React `renderToString`)

```
docs/tsx_demo/tsx_demo.tsx       # default-exported React component
docs/tsx_demo/page.json          # { "renderer": "react", "ssr": true }
docs/tsx_demo/index.md           # optional, the markdown wrapper if you want one
```

```tsx
// tsx_demo.tsx
export default function TsxDemo() {
  return <div className="tsx-demo"><h2>Hello</h2></div>;
}
```

The component is server-rendered at build time. Use this when you want the React ecosystem (hooks, JSX, npm-supplied React components).

### 2. MoonBit (`pub fn render() -> Node[Unit]`)

```
docs/ssr_test_component/ssr_test_component.mbt
docs/ssr_test_component/moon.pkg.json          # standard MoonBit package manifest
docs/ssr_test_component/page.json              # { "ssr": true }
```

```moonbit
using @luna { h, text, attr_static, type Node, type Attr }

pub fn render() -> Node[Unit] {
  h("div", [("class", attr_static("box"))], [
    h("h2", [], [text("Local SSR Component")]),
    h("p", [], [text("Defined in docs/ssr_test_component/")]),
  ])
}
```

Use this when the component is small, pure, and you don't want a TS toolchain on the page.

### 3. Client-side web components (islands)

Drop a Custom Element implementation into the configured islands dir (e.g. `components/my-counter.js`). Reference it in markdown like normal HTML:

```markdown
## Interactive demo

<my-counter></my-counter>
```

`astra build` runs rolldown over `islands.dir` to produce hashed bundles under `islands.basePath`, and the runtime loader (`loader.js`) hydrates the elements on first visibility. This is the path the Luna components site (`website/components/`) uses.

## CLI workflow

```sh
# dev server
astra dev

# one-shot static build → out_dir/
astra build

# (no top-level deploy subcommand yet — chain with wrangler / pages CLI;
#  `deploy: "cloudflare"` in astra.config.json only influences template
#  output, not an automated push)
```

`astra` is itself a thin native launcher that delegates to a JS CLI under `.mooncakes/mizchi/astra/cmd/astra` (same pattern as sol). Inside a moon project with `mizchi/astra` resolved, `astra dev` works out of the box.

## Source of truth

- Config resolution order: `astra/src/cli/cli.mbt` (`astra.config.json` → `sol.config.json` fallback)
- Build pipeline: `astra/src/cli/build.mbt`
- Dev server: `astra/src/cli/dev.mbt`
- Mars middleware entry: `astra/src/middleware/`
- Reference site that exercises every feature: `astra/examples/sol_docs/`
- Live luna.mbt site (CF Workers Static Assets): `website/` — `astra.config.json` + `wrangler.json` + the `deploy-website` GitHub workflow
- User-facing guide pages: `astra/docs/guide/{index,configuration,markdown}.md`
- Astra vs. sol parity gap notes: `astra/docs/parity-notes.md`
