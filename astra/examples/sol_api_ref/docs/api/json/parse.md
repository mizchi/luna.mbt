---
title: json.parse
description: Decode JSON text into a value.
---

<p class="crumbs"><a href="/">Home</a> · <a href="/api/">API</a> · <a href="/api/json/">json</a> · parse</p>

# `json.parse`

<code class="sig">parse(text: string): unknown</code>

Parses a JSON document. Throws `SyntaxError` on malformed input.

## Parameters

- `text` — a JSON document as a string.

## Returns

`unknown` — the decoded value. Cast or validate before use.

## Throws

- `SyntaxError` — if `text` is not valid JSON.

## Example

```ts
import { parse } from "@example/json";

parse(`{"x":1}`);       // { x: 1 }
parse(`[1, 2, 3]`);     // [1, 2, 3]
parse(`null`);          // null
```

## See also

- [`json.stringify`](/api/json/stringify/)
