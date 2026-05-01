---
description: A blog post example
---

# Post Page

This is a dynamically generated post page.

The URL path is determined by the `slug` parameter in `page.json`.

## How it works

1. Create a `_slug_` directory (parameter name between underscores)
2. Add `page.json` with `staticParams` array
3. Add `index.md` as the template
4. Astra generates a page for each param in `staticParams`

## Example

```json
{
  "staticParams": [
    { "slug": "hello-world" },
    { "slug": "getting-started" }
  ]
}
```

This generates:
- `/posts/hello-world/`
- `/posts/getting-started/`
