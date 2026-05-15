---
title: array.map
description: Apply a function to every element.
---

<p class="crumbs"><a href="/">Home</a> · <a href="/api/">API</a> · <a href="/api/array/">array</a> · map</p>

# `array.map`

<code class="sig">map&lt;T, U&gt;(input: T[], fn: (value: T, index: number) =&gt; U): U[]</code>

Returns a new array where each element is the result of applying `fn` to
the corresponding element of `input`.

## Parameters

- `input` — the source array.
- `fn` — projection from `T` to `U`. Receives `(value, index)`.

## Returns

`U[]` — an array the same length as `input`.

## Example

```ts
import { map } from "@example/array";

map([1, 2, 3], (n) => n * 2);          // [2, 4, 6]
map(["a", "b"], (s, i) => `${i}:${s}`); // ["0:a", "1:b"]
```

## See also

- [`array.filter`](/api/array/filter/)
- [`array.reduce`](/api/array/reduce/)
