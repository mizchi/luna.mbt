---
title: 🌗 Luna SSG
description: A static site generator built with MoonBit
layout: home
---

# Luna SSG

A static site generator built with MoonBit. Generate VitePress/Docusaurus-style documentation sites.

## Features

- **File-based Routing** - Auto-generate routes from Markdown files in `docs/`
- **Frontmatter Support** - Define page metadata in YAML format
- **VitePress-style Theme** - Auto-generated navigation, sidebar, and table of contents
- **Multi-language Support** - i18n with automatic fallback to default locale
- **Island Architecture** - Partial hydration support (coming soon)

## Quick Start

```bash
# Create docs directory
mkdir docs

# Add a Markdown file
echo "# Hello World" > docs/index.md

# Build the site
sol ssg build
```

## Configuration

```json
{
  "ssg": {
    "docs": "docs",
    "output": "dist",
    "title": "My Documentation",
    "nav": [
      { "text": "Guide", "link": "/guide/" }
    ]
  }
}
```
