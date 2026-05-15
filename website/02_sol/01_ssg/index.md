---
title: Sol SSG (moved to Astra)
---

# Sol SSG → Astra

> **This page is preserved for backwards-compatible links only.**
> Sol's built-in SSG mode (`sol new --ssg`, `sol build` for static
> sites) was extracted into a separate package, **[Astra](/astra/)**,
> in sol 0.16. The `--ssg` flag was removed from `sol new` at the
> same time.

For docs / blog / static-site work, use Astra directly:

- [Astra overview](/astra/)
- [Astra — Getting Started](/astra/getting-started/)
- [Astra — Mount on Mars](/astra/mount-on-mars/)
- [Astra — Deploy](/astra/deploy/)

## Why the split

Astra has no dependency on sol (`deps: mars + markdown + luna`). The
build path no longer requires running a sol server — `astra build`
walks every URL the in-process middleware can serve and writes the
rendered body to disk, so the typical deploy is "build once, serve
from any static host" (Cloudflare Workers Static Assets, GitHub Pages,
S3, etc.). See the [astra README](https://github.com/mizchi/luna.mbt/tree/main/astra)
for the full rationale.

## Migration cheat sheet

| Old (sol ≤ 0.15) | New (astra 0.22.3+) |
|------------------|---------------------|
| `sol new my-docs --ssg` | `mkdir my-docs && cd my-docs && mkdir docs && echo "# Hello" > docs/index.md` |
| `sol dev` (SSG mode) | `astra dev` |
| `sol build` (SSG mode) | `astra build --out ./dist` |
| `sol.config.json` with `ssg`/`docs` section | `astra.config.json` (same field names; `sol.config.json` still read as a fallback for legacy projects) |

For the original quick-start, install Astra and follow [Getting Started](/astra/getting-started/):

```sh
moon install mizchi/astra/cmd/astra   # or: pnpm add -g @luna_ui/astra
```

## Hybrid (Sol app + Astra docs)

If you need an SSR app and a docs surface in one binary, mount Astra
as Mars middleware alongside Sol's routes — that path is covered in
[Astra — Mount on Mars](/astra/mount-on-mars/).
