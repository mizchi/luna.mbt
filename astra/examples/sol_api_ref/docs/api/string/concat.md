---
title: string.concat
description: Join two strings into one.
---

<p class="crumbs"><a href="/">Home</a> · <a href="/api/">API</a> · <a href="/api/string/">string</a> · concat</p>

# `string.concat`

<code class="sig">concat(a: string, b: string): string</code>

Returns a new string composed of `a` followed by `b`. The input strings are
not modified.

## Parameters

- `a` — the leading string.
- `b` — the trailing string.

## Returns

`string` — the concatenation.

## Example

```ts
import { concat } from "@example/string";

concat("foo", "bar"); // "foobar"
concat("", "x");       // "x"
```

## See also

- [`string.slice`](/api/string/slice/)
- [`array.reduce`](/api/array/reduce/)
