---
title: string.slice
description: Extract a substring by index range.
---

<p class="crumbs"><a href="/">Home</a> · <a href="/api/">API</a> · <a href="/api/string/">string</a> · slice</p>

# `string.slice`

<code class="sig">slice(input: string, start: number, end?: number): string</code>

Returns the substring of `input` between `start` (inclusive) and `end`
(exclusive). Indices clamp to `[0, input.length]`.

## Parameters

- `input` — the source string.
- `start` — the inclusive start index. Negative values count from the end.
- `end` — the exclusive end index. Defaults to `input.length`.

## Returns

`string` — the extracted substring.

## Example

```ts
import { slice } from "@example/string";

slice("hello", 1, 4); // "ell"
slice("hello", -3);    // "llo"
slice("hello", 0, 99); // "hello"
```

## See also

- [`string.split`](/api/string/split/)
