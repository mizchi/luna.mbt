---
title: string.split
description: Split a string on a separator.
---

<p class="crumbs"><a href="/">Home</a> · <a href="/api/">API</a> · <a href="/api/string/">string</a> · split</p>

# `string.split`

<code class="sig">split(input: string, separator: string): string[]</code>

Splits `input` into segments delimited by `separator`. The separator itself
is not included in any segment.

## Parameters

- `input` — the string to split.
- `separator` — the delimiter. Empty separator splits between every
  code unit.

## Returns

`string[]` — the resulting segments. Always non-empty; an input that does
not contain `separator` returns a single-element array.

## Example

```ts
import { split } from "@example/string";

split("a,b,c", ",");   // ["a", "b", "c"]
split("noop", ",");    // ["noop"]
split("abc", "");      // ["a", "b", "c"]
```

## See also

- [`string.concat`](/api/string/concat/)
- [`array.filter`](/api/array/filter/)
