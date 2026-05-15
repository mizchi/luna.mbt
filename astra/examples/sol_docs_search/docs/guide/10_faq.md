---
title: FAQ
description: Common questions and gotchas when combining Astra with PageFind.
---

<search-box></search-box>

# FAQ

A handful of issues come up often enough that they earn their own entry. If you hit one that is not listed here, please open an issue on the repo.

## Why is the search box stuck on "Search index not available"?

The `<search-box>` Web Component logs that message when the dynamic import of `/pagefind/pagefind.js` throws. The two most common causes:

1. **You are running `astra dev`.** Dev mode does not run any post-build steps; PageFind has never written the index. Build + serve from `dist/` instead.
2. **The post-build step did not run.** Verify that `dist/pagefind/` exists. If not, run `pnpm exec pagefind --site dist` manually and check the stdout.

## Search results show stale content

PageFind only re-crawls when explicitly invoked. If you edited a Markdown file but only ran `astra build` (not the chained `astra build && pagefind`), the index still references the old HTML. The fix is to always go through `pnpm build`, or to run `pagefind --site dist` whenever you touch the docs.

## Build is slow on large sites

PageFind is fast — typical throughput is 200-500 pages per second on modest hardware. The slow part is usually `astra build` itself for big trees. If the bottleneck is PageFind, look at `--exclude-selectors` to drop the parts of the page that do not matter (header chrome, footer, sidebar).

## My islands don't hydrate inside search results

Search results are static HTML excerpts — they do not run scripts. If you click a result link, the destination page hydrates as normal. If you want hydration inside the result preview, you have to render the island in your own UI; PageFind does not execute JavaScript inside its fragments.

## Can I use PageFind without a static build step?

Technically yes — there is a JavaScript indexer that runs in-browser — but it's slower, requires every page in memory, and defeats the bandwidth argument. Stick with the CLI for anything past a toy demo.

## Does PageFind respect `robots.txt` / noindex?

It respects the `data-pagefind-ignore="all"` body attribute and the meta robots tag `<meta name="robots" content="noindex">`. It does not read `robots.txt`. If you have pages you want crawlers to skip *and* you want to keep them out of the search index, set the meta tag explicitly on those pages.

## How do I exclude a single section of a page?

Wrap it in `<div data-pagefind-ignore>…</div>`. The content is rendered normally but PageFind treats it as if it were not there.

## Why aren't my code blocks searchable?

Either the `--exclude-selectors` flag is set to drop them, or PageFind decided the block is "boilerplate" because the same content repeats across many pages. If you specifically want code samples in the index, remove the exclude rule and consider adding `data-pagefind-weight="0.5"` so they don't dominate ranking.

## What's the relationship to `pagefind-extended`?

`pagefind-extended` is a fork that adds support for indexing PDFs and a few other binary formats. The base `pagefind` package handles HTML only. For a docs site, HTML is enough.

## Can I bundle PageFind's JS into my own JS to avoid the network roundtrip?

Yes, but the API isn't designed for it and you'll lose lazy fragment loading. The recommended pattern is to leave `pagefind.js` as a separate `<script type="module">` and let HTTP/2 multiplex the parallel fetches.
