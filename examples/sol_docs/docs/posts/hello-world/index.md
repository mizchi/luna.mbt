---
title: Hello World (Static)
description: This is the static version of Hello World page
---

# Hello World - Static Page

This is a **static page** that should take priority over the dynamically generated `_slug_` version.

## Priority Rule

When both exist:
- `posts/hello-world/index.md` (static)
- `posts/_slug_/index.md` with `{ "slug": "hello-world" }` (dynamic)

The static page should be used.
