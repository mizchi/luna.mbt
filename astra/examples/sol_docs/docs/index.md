---
title: Astra Demo
description: Demo site for Unified Progressive Architecture
---

# Astra Demo

This is a demo site showcasing the **Unified Progressive Architecture** features.

## Features

- **Static Site Generation** - Markdown pages compiled to HTML
- **Component Integration** - MoonBit components with SSR + Hydration
- **Client Router** - Hybrid navigation with scroll restoration
- **Cloudflare Deploy** - Optimized for Cloudflare Pages

## Pages

- [About](/about/) - About this demo
- [Guide](/guide/) - Getting started guide

## Architecture

```
docs/
├── index.md          # Home page (static)
├── about/
│   └── index.md      # About page (static)
└── guide/
    └── index.md      # Guide page (static)
```

## Build Output

When built with `deploy.target: "cloudflare"`:

- `dist/_routes.json` - Cloudflare Pages routing
- `dist/_luna/manifest.json` - Client chunk manifest
