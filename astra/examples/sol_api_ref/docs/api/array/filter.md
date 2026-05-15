---
title: array.filter
description: Keep elements matching a predicate.
---

<p class="crumbs"><a href="/">Home</a> · <a href="/api/">API</a> · <a href="/api/array/">array</a> · filter</p>

# `array.filter`

<code class="sig">filter&lt;T&gt;(input: T[], predicate: (value: T, index: number) =&gt; boolean): T[]</code>

Returns a new array containing only the elements of `input` for which
`predicate` returns truthy.

## Parameters

- `input` — the source array.
- `predicate` — `(value, index) => boolean`.

## Returns

`T[]` — the kept elements, in their original order.

## Example

```ts
import { filter } from "@example/array";

filter([1, 2, 3, 4], (n) => n % 2 === 0); // [2, 4]
filter(["", "a", ""], (s) => s !== "");    // ["a"]
```

## See also

- [`array.map`](/api/array/map/)
