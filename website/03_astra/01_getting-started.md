---
title: Getting Started
description: Install Astra, create your first docs project, and run the build
---

# Getting Started

## Prerequisites

- MoonBit toolchain (`moon`)
- Either `moon install mizchi/astra/cmd/astra` or `pnpm add -g @luna_ui/astra` for the CLI

The npm wrapper exists for users who already have Node.js but not the MoonBit toolchain — both end up with the same binary on `$PATH`.

## Project layout

Astra reads its content tree from `docs/` (or whatever `docs_dir` points at in `astra.config.json`):

```
my-docs/
├── astra.config.json     # optional — defaults work for a small site
├── docs/
│   ├── index.md          # → /
│   └── guide/
│       ├── index.md      # → /guide/
│       └── routing.md    # → /guide/routing/
└── dist/                 # → astra build output (gitignored)
```

A minimum `astra.config.json`:

```json
{
  "title": "My Docs",
  "docs_dir": "docs",
  "output_dir": "dist"
}
```

If a config field is omitted, Astra uses its defaults (defined in `@astra.SsgConfig::default()`).

## First page

`docs/index.md`:

```md
---
title: Welcome
---

# Welcome

This is rendered by Astra.
```

The frontmatter `title` flows into the page's `<title>` and the auto-generated sidebar.

## Build

```sh
astra build --out ./dist
```

This crawls every URL the middleware exposes (every Markdown page plus bundled assets) and writes `<out>/<url>/index.html` for each page, alongside the asset tree (`/assets/main.css`, `/scripts/loader.js`, etc.).

## Dev server

```sh
astra dev --port 7777
```

The dev server uses the same `Middleware::handler()` as the build, so what you see in the browser at `http://localhost:7777` is what `astra build` will write to disk. There is no second renderer.

## Next

- [Mount on Mars](/astra/mount-on-mars/) — embed Astra in an existing Mars server
- [Deploy](/astra/deploy/) — ship the build output
