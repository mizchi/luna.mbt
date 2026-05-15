---
title: Configuration
description: Configuring astra.config.json and PageFind CLI flags for a documentation site.
---

<search-box></search-box>

# Configuration

Astra reads `astra.config.json` from the project root. PageFind takes its options either from CLI flags or from a `pagefind.yml` adjacent to the input directory. This page covers the fields you typically need for a docs site.

## astra.config.json fields

```json
{
  "title": "Astra Docs Search",
  "description": "A docs example wired to PageFind.",
  "docs_dir": "docs",
  "out_dir": "dist",
  "base_url": "/",
  "trailing_slash": true,
  "islands": {
    "dir": "docs/public/islands",
    "basePath": "/islands/"
  },
  "nav": [
    { "text": "Home", "link": "/" },
    { "text": "Guide", "link": "/guide/01_intro/" }
  ],
  "sidebar": {
    "/guide/": [
      { "text": "Intro", "link": "/guide/01_intro/" }
    ]
  }
}
```

Key fields:

- `docs_dir` — root for the markdown tree. Every `.md` becomes a route.
- `out_dir` — where `astra build` writes the static site. PageFind runs against this directory.
- `trailing_slash` — when `true`, routes are emitted as `foo/index.html` rather than `foo.html`. PageFind's link rewriting works with both forms; the trailing-slash style avoids a redirect step on most CDNs.
- `islands` — pointer to the directory whose `.js` files are bundled with rolldown and emitted under `dist/islands/`.
- `nav` / `sidebar` — declarative navigation. Both are optional but make a docs site much more navigable.

## PageFind CLI flags

For most projects, the only flag you need is `--site` (the directory PageFind should crawl):

```sh
pagefind --site dist
```

Other useful flags:

- `--root-selector "main"` — restrict indexing to the main content region, ignoring header and footer chrome.
- `--exclude-selectors "code,pre"` — drop code blocks from the index (useful if you have a lot of repeated keywords like `function` that distort relevance).
- `--glob "**/*.html"` — limit which files are indexed; default is every `.html` and `.htm`.
- `--output-subdir pagefind` — change the output dir under `dist/`. The default `pagefind/` matches what `/pagefind/pagefind.js` expects in the client; only change this if you also patch the import path.
- `--keep-index-url` — preserves the trailing-slash form in result URLs; matches Astra's default.

Persisted as `pagefind.yml`:

```yaml
site: dist
root_selector: main
exclude_selectors:
  - "code"
  - "pre"
```

## Frontmatter that PageFind respects

PageFind reads a small set of `data-pagefind-*` attributes and falls back to the document title. The two most useful ones for an Astra site:

- `<h1 data-pagefind-meta="title">Page name</h1>` — overrides the title shown in results. Astra emits the frontmatter `title` as the page `<title>` automatically, so this is rarely necessary.
- `<p data-pagefind-meta="description">…</p>` — extra metadata that ends up on `result.meta.description`.

You can also exclude an entire page with `<body data-pagefind-body data-pagefind-ignore="all">`, useful for utility pages like `/sitemap/` that you do not want in the search index.
