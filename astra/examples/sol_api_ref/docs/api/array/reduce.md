---
title: array.reduce
description: Fold an array into a single value.
---

<p class="crumbs"><a href="/">Home</a> · <a href="/api/">API</a> · <a href="/api/array/">array</a> · reduce</p>

# `array.reduce`

<code class="sig">reduce&lt;T, A&gt;(input: T[], fn: (acc: A, value: T, index: number) =&gt; A, initial: A): A</code>

Folds `input` from the left, threading an accumulator through `fn`. Returns
`initial` for an empty array.

## Parameters

- `input` — the source array.
- `fn` — `(acc, value, index) => acc`.
- `initial` — the starting accumulator.

## Returns

`A` — the final accumulator.

## Example

```ts
import { reduce } from "@example/array";

reduce([1, 2, 3, 4], (acc, n) => acc + n, 0); // 10
reduce(["a", "b"], (acc, s) => acc + s, "");   // "ab"
```

## See also

- [`array.map`](/api/array/map/)
- [`array.filter`](/api/array/filter/)
