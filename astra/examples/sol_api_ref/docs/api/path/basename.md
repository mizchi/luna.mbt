---
title: path.basename
description: Return the trailing segment of a path.
---

<p class="crumbs"><a href="/">Home</a> · <a href="/api/">API</a> · <a href="/api/path/">path</a> · basename</p>

# `path.basename`

<code class="sig">basename(path: string, ext?: string): string</code>

Returns the last segment of `path`. If `ext` is supplied and `path` ends
with it, the suffix is stripped.

## Parameters

- `path` — the input path.
- `ext` — optional extension to strip, including the leading dot.

## Returns

`string` — the trailing segment.

## Example

```ts
import { basename } from "@example/path";

basename("/a/b/c.txt");          // "c.txt"
basename("/a/b/c.txt", ".txt"); // "c"
basename("a/");                    // "a"
```

## See also

- [`path.join`](/api/path/join/)
