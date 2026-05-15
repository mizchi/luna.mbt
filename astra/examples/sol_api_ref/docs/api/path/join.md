---
title: path.join
description: Join path segments with a single separator.
---

<p class="crumbs"><a href="/">Home</a> · <a href="/api/">API</a> · <a href="/api/path/">path</a> · join</p>

# `path.join`

<code class="sig">join(...segments: string[]): string</code>

Joins the given segments with `/`, collapsing duplicate separators and
removing trailing slashes. Empty segments are ignored.

## Parameters

- `...segments` — zero or more path segments.

## Returns

`string` — the joined path. Returns `"."` when no non-empty segments are
provided.

## Example

```ts
import { join } from "@example/path";

join("a", "b", "c");      // "a/b/c"
join("/a/", "/b/");        // "/a/b"
join("a", "", "b");        // "a/b"
join();                    // "."
```

## See also

- [`path.basename`](/api/path/basename/)
