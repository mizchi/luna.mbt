---
title: Getting Started
description: Guide to using Luna with Astra
---

# Getting Started

This guide shows how to use Luna's Unified Progressive Architecture.

## Installation

```bash
# Install Luna CLI
npm install -g @luna_ui/cli

# Create new project
luna init my-site
cd my-site
```

## Project Structure

```
my-site/
├── astra.json        # Configuration
├── docs/             # Content directory
│   ├── index.md      # Home page
│   └── guide/
│       └── index.md  # This page
└── dist/             # Build output
```

## Configuration

Create `astra.json`:

```json
{
  "$schema": "../../schemas/astra.schema.json",
  "title": "My Site",
  "docs_dir": "docs",
  "out_dir": "dist",
  "deploy": {
    "target": "cloudflare"
  }
}
```

## Build

```bash
# Build static site
astra build

# Development server
astra dev
```

## Links

- [Home](/)
- [About](/about/)
