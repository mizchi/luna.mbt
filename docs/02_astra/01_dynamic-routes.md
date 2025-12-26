---
title: Dynamic Routes
description: Generate static pages from dynamic parameters
---

# Dynamic Routes

Astra supports dynamic route generation using the `_param_` directory naming pattern. This allows you to generate multiple static pages from a single template.

## Basic Usage

### Directory Structure

```
docs/
└── posts/
    ├── index.md              # Posts listing page
    └── _slug_/               # Dynamic parameter directory
        ├── page.json         # Static params configuration
        └── index.md          # Template for each page
```

### Configuration (page.json)

Define which pages to generate using `staticParams`:

```json
{
  "staticParams": [
    { "slug": "hello-world" },
    { "slug": "getting-started" },
    { "slug": "advanced-topics" }
  ]
}
```

### Template (index.md)

The template file is used for all generated pages:

```markdown
---
description: A blog post
---

# Post Page

This content is shared across all generated pages.
```

### Generated Output

With the above configuration, Astra generates:

- `/posts/hello-world/index.html`
- `/posts/getting-started/index.html`
- `/posts/advanced-topics/index.html`

## Parameter Naming

The parameter name is extracted from the directory name:

| Directory | Parameter |
|-----------|-----------|
| `_slug_` | `slug` |
| `_id_` | `id` |
| `_category_` | `category` |

## Auto-Generated Titles

If no `title` is specified in frontmatter, Astra generates one from the parameter value:

- `hello-world` → "Hello World"
- `getting-started` → "Getting Started"

## Multiple Parameters

You can use multiple parameters in nested directories:

```
docs/
└── blog/
    └── _category_/
        └── _slug_/
            ├── page.json
            └── index.md
```

```json
{
  "staticParams": [
    { "category": "tech", "slug": "intro-to-moonbit" },
    { "category": "tech", "slug": "advanced-patterns" },
    { "category": "news", "slug": "release-notes" }
  ]
}
```

## Comparison with Client-Side Routing

| Feature | Dynamic Routes (`_slug_`) | Client-Side (BrowserRouter) |
|---------|---------------------------|----------------------------|
| SEO | Full static HTML | Initial page only |
| Build time | Generates all pages | Single entry point |
| Navigation | Full page reload | SPA-like instant |
| Use case | Blog posts, docs | Interactive apps |

For client-side dynamic routing (SPA), see [Islands](/astra/islands/).
