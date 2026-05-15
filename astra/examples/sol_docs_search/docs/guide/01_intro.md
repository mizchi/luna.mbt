---
title: Introduction
description: What Astra is, why client-side search matters, and how PageFind fits into a MoonBit-driven static site.
---

<search-box></search-box>

# Introduction

Astra is a **mountable static site generator** built on top of the Mars HTTP middleware framework. It takes a tree of Markdown under `docs/` and turns it into a fully-static `dist/` directory: HTML for every route, hashed assets, and a sitemap. Because the build output is pure files, you can host it on any object store, CDN, or edge platform without running a long-lived server.

Documentation sites in particular benefit from **two** things that Astra does well:

1. **Markdown-first authoring.** A writer never has to touch component code. Every `.md` file becomes a route; `index.md` is the directory root; `docs/public/` is copied as-is to the output.
2. **Static distribution.** Once the site is generated, the cost of serving it is effectively zero. You upload the tree to Cloudflare Pages, GitHub Pages, S3, or any HTTP server.

The piece traditionally missing from a fully-static documentation site is **search**. Classic options trade off operationally:

- **Algolia DocSearch** is excellent but requires applying for a free plan, a periodic crawler, and an API key embedded in the page. The index lives off-site.
- **Lunr.js** is fully client-side but the index is built in JavaScript at build time, and you have to wire it into every page yourself.
- **Server-side search** (Elasticsearch, Meilisearch, Typesense) defeats the point of a static deploy because you now need a runtime.

[PageFind](https://pagefind.app/) is the third option that addresses each of these. It is a **post-build static indexer**: you give it the directory of HTML files that your generator just emitted, and it writes a chunked binary index plus a small JS bundle into `dist/pagefind/`. The browser fetches only the index shards that match a given query — typical real-world docs sites end up loading 100-300 KB at search time, regardless of how big the underlying corpus is.

This example shows the smallest reasonable wiring: chain `astra build` with `pagefind --site dist` in `package.json`, drop a `<search-box>` Web Component on the page, and you have working search.

## What you'll learn

- How Astra discovers routes from `docs/`.
- How to install PageFind as a devDependency and run it as a post-build step.
- How a Web Component can dynamically import `/pagefind/pagefind.js` and render results.
- How to deploy the combined static output to Cloudflare or GitHub Pages.

## When this approach is the wrong fit

- **Massive corpora (10k+ pages).** PageFind scales well into the low thousands, but if you are indexing a forum or a generated API reference of 50k pages, you probably want a server-side engine.
- **Authenticated content.** PageFind indexes everything visible at build time. If your search has to respect per-user ACLs, generate the index in a service that knows about identity.
- **Faceted search.** PageFind supports basic filters via meta tags, but rich faceting (price, category, date ranges) is much easier in a hosted engine.

For the typical 10-500 page documentation site that this example targets, the static post-build flow is the right answer.
