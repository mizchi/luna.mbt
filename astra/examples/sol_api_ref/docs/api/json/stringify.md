---
title: json.stringify
description: Encode a value as JSON text.
---

<p class="crumbs"><a href="/">Home</a> · <a href="/api/">API</a> · <a href="/api/json/">json</a> · stringify</p>

# `json.stringify`

<code class="sig">stringify(value: unknown, indent?: number): string</code>

Encodes `value` as a JSON document. Without `indent`, output is compact
(no whitespace). With `indent > 0`, output is pretty-printed.

## Parameters

- `value` — any JSON-serialisable value.
- `indent` — optional indent width in spaces.

## Returns

`string` — the JSON encoding.

## Throws

- `TypeError` — if `value` contains a circular reference.

## Example

```ts
import { stringify } from "@example/json";

stringify({ x: 1 });       // `{"x":1}`
stringify([1, 2], 2);      // `[\n  1,\n  2\n]`
```

## See also

- [`json.parse`](/api/json/parse/)
