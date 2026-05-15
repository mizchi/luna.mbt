---
title: Sol API Reference
description: A worked API reference example — four modules, sixteen symbol pages, auto-generated sidebar.
layout: home
---

# Sol API Reference

A minimal API reference site rendered by `astra build`. Each symbol gets its
own page under `/api/<module>/<symbol>/` and the sidebar is generated from
the directory tree (`sidebar: "auto"` in `astra.config.json`).

## Modules

<div class="module-grid">

<a href="/api/string/">
<h3>string</h3>
<p>String manipulation utilities — concat, split, slice.</p>
</a>

<a href="/api/array/">
<h3>array</h3>
<p>Array transformations — map, filter, reduce.</p>
</a>

<a href="/api/json/">
<h3>json</h3>
<p>JSON encoding and decoding — parse, stringify.</p>
</a>

<a href="/api/path/">
<h3>path</h3>
<p>Cross-platform path helpers — join, basename.</p>
</a>

</div>

## How this is laid out

```
docs/
├── index.md                # this page
├── api/
│   ├── index.md            # /api/ — module index
│   ├── string/
│   │   ├── index.md        # /api/string/
│   │   ├── concat.md       # /api/string/concat/
│   │   ├── split.md
│   │   └── slice.md
│   ├── array/...
│   ├── json/...
│   └── path/...
└── public/og.svg
```

Every `.md` becomes a route. `index.md` is the directory root. The sidebar
is regenerated from this tree on each build.
