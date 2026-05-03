---
title: Posts
description: Blog posts example with dynamic routes
---

# Posts

This example demonstrates the `_slug_` pattern for static site generation with dynamic routes.

## Available Posts

- [Hello World](/posts/hello-world/)
- [Getting Started](/posts/getting-started/)
- [Advanced Topics](/posts/advanced-topics/)

## How Dynamic Routes Work

In Astra SSG, you can create dynamic routes using the `_param_` directory naming convention:

```
posts/
  index.md          # Posts listing (this page)
  _slug_/           # Dynamic parameter directory
    page.json       # Static params configuration
    index.md        # Template for each page
```

At build time, Astra reads `page.json` and generates a page for each entry in `staticParams`.
