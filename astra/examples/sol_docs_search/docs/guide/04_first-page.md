---
title: Your first page
description: Authoring a Markdown page and verifying that Astra picks it up.
---

<search-box></search-box>

# Your first page

The fastest way to confirm an Astra install is working is to add a Markdown file and watch it appear in `dist/`.

## File layout

Drop a new file at `docs/guide/hello.md`:

```markdown
---
title: Hello, Astra
description: My very first Astra page.
---

# Hello, Astra

This is a brand new page. It will live at `/guide/hello/` once the site builds.

- Astra picks it up automatically because it sits under `docs_dir`.
- The frontmatter `title` becomes the `<title>` tag in the rendered HTML.
- The frontmatter `description` is exposed to the layout for the `<meta name="description">` tag.
```

After running `pnpm build`, the file appears at `dist/guide/hello/index.html`. Open it in a browser and confirm the title bar reads `Hello, Astra`.

## How routes are derived

Astra derives the URL from the path on disk:

| File | URL |
|------|-----|
| `docs/index.md` | `/` |
| `docs/about.md` | `/about/` |
| `docs/guide/intro.md` | `/guide/intro/` |
| `docs/guide/index.md` | `/guide/` |
| `docs/ja/index.md` | `/ja/` (when i18n is enabled) |

Astra strips leading numeric prefixes like `01_` from filenames before deriving the URL. `docs/guide/01_intro.md` becomes `/guide/intro/`, not `/guide/01_intro/`. The numeric prefix is purely for ordering on disk and in the sidebar — the URL stays readable. If you want a fully custom URL, rename the file; there is no "permalink" frontmatter today.

## Page-local front matter

A small but useful set of frontmatter keys:

- `title` — page title. Required for nice OG cards.
- `description` — meta description; used in the search results' "excerpt" line.
- `layout` — `"page"` (default), `"home"` (used for landing pages with custom CSS), `"blank"` (no chrome).
- `sidebar` — set to `false` to suppress the sidebar on a single page (useful for landing pages).
- `revalidate` — only meaningful when serving through the Mars middleware mount. Ignored in pure SSG mode.

## A note about hot reload

`astra dev` watches `docs/` and re-renders incrementally. PageFind is **not** invoked during dev — `astra dev` does not run any post-build steps, and the search box silently switches to its "index not available" branch. This is intentional: rebuilding the search index on every keystroke is expensive, and dev-time search would only show stale results anyway. If you need to test the search UI locally, run `pnpm build && pnpm dlx http-server dist`.
