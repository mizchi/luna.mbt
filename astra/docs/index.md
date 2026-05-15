---
title: 🌗 Astra
description: A static site generator built with MoonBit
layout: home
---

# Astra

A markdown-driven static site generator written in MoonBit. Generate
VitePress / Docusaurus-style documentation sites with `astra build`.
The Mars-middleware form is available for embedding the same renderer
in a long-running server, but the default workflow is "build once,
serve from any static host."

## Features

- **File-based Routing** - Auto-generate routes from Markdown files in `docs/`
- **Frontmatter Support** - Define page metadata in YAML format
- **VitePress-style Theme** - Auto-generated navigation, sidebar, and table of contents
- **Multi-language Support** - i18n with automatic fallback to default locale
- **Island Architecture** - Partial hydration via the `islands/` directory

## Quick Start

```bash
# Create docs directory
mkdir docs

# Add a Markdown file
echo "# Hello World" > docs/index.md

# Build the site to dist/
astra build
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
