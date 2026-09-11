---
title: Astra
description: Mountable Mars middleware for static-site generation in MoonBit
---

# Astra

> **Experimental**: Astra is under active development. APIs may change.

Astra is a mountable [Mars](https://mooncakes.io/docs/mizchi/mars/) middleware for static-site generation in MoonBit. It renders Markdown / MDX documentation pages on request and serves bundled assets (loader runtime, default CSS, Shiki syntax highlighting). Pair it with the `astra` CLI to dump the same output as a static tree (`astra build`) or serve it from a dev server (`astra dev`).

## What makes Astra different

The middleware and the static dump render through the **same** `Middleware`. `astra dev` serves it over HTTP; the build crawler calls `Middleware::render_url(url)` for each entry the middleware exposes and writes the response body to disk — no Mars `Server`, no localhost listener. So if a page renders correctly via `astra dev`, it is also correct in the static dump — there is no second renderer to keep in sync.

That property gives Astra two postures:

- **Library**: mount on any Mars server alongside your application routes. The same MoonBit app can serve a `/docs/*` documentation tree and live API endpoints from one binary.
- **Static site**: skip the server entirely. `astra build --out ./dist` produces a self-contained directory you can ship to GitHub Pages, Cloudflare, Vercel, or any static host.

### Pages the compiler checks

A page can be written as `<name>.mbt.md` instead of `<name>.md`. Astra routes it exactly like Markdown — `guide/intro.mbt.md` becomes `/guide/intro/`, and `guide/intro.ja.mbt.md` is its `ja` translation — but the file is also MoonBit's literate-markdown format. Every fence tagged ` ```mbt check ` is compiled by `moon check` and executed by `moon test`:

````md
```mbt check
///|
test "the sample in the docs actually runs" {
  let cfg = @astra.SsgConfig::default()
  let mw = @middleware.create(cfg, cwd=".")
  assert_true(mw.list_urls().length() >= 0)
}
```
````

Put such pages in a directory with a `moon.pkg`, in a module listed in your `moon.work`, and sample code stops being prose the compiler never sees. [Mount on Mars](/astra/mount-on-mars/) is written this way — the snippets on it are compiled on every `moon check`. Fences tagged plain ` ```mbt ` or ` ```moonbit ` are left as prose, so illustrative fragments still render fine.

## When to choose Astra over Sol

| Need | Reach for |
|------|-----------|
| Docs / blog with mostly static content | **Astra** |
| Embedded docs alongside an existing Mars app | **Astra** (mounted as middleware) |
| Full SSR app with file-based routing, API routes, server actions | [**Sol**](/sol/) |
| Both, in one repository | Sol with Astra mounted under `/docs/*` |

Astra has no edge to Sol: its dependency graph is built on mars, markdown and luna (plus support packages), and never reaches Sol. Sol pulls Astra in for its docs surface but the inverse is not true.

## Sections

- [Getting Started](/astra/getting-started/) — install, first project, first build
- [Mount on Mars](/astra/mount-on-mars/) — embed Astra in an existing Mars server (written as a `.mbt.md` page, so its samples are compiled)
- [Deploy](/astra/deploy/) — GitHub Pages, Cloudflare, Vercel, Netlify

## Install

Library:

```sh
moon add mizchi/astra
moon add mizchi/mars
moon add mizchi/luna
```

CLI:

```sh
moon install mizchi/astra/cmd/astra   # → $MOON_HOME/bin/astra
# or via npm if you have node but not moon
pnpm add -g @luna_ui/astra            # 0.23.0
```

## Quick taste

```bash
mkdir docs && echo "# Hello Astra" > docs/index.md
astra build --out ./dist
# dist/index.html now renders the page
```

A full working example with i18n, MDX, blog, and components lives at [`astra/examples/sol_docs/`](https://github.com/mizchi/luna.mbt/tree/main/astra/examples/sol_docs) in the source repository.
