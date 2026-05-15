---
title: Getting Started
description: Overview and setup guide for Astra
---

# Getting Started

Astra is a markdown-driven static site generator written in MoonBit.
The default workflow is `astra build` → static tree → any CDN. The same
renderer can also be mounted on a Mars server when you need on-request
rendering, but the static path is the primary form.

## Prerequisites

- MoonBit installed
- Node.js 18+ installed

## Directory Structure

```
project/
├── docs/
│   ├── index.md          # Home page (/)
│   └── guide/
│       ├── index.md      # Guide index (/guide/)
│       └── config.md     # Config page (/guide/config)
├── astra.config.json     # Configuration file (primary)
└── dist/                 # Output directory (auto-generated)
```

`sol.config.json` is read as a fallback when `astra.config.json` is
missing — only relevant for projects that started under sol's SSG
mode before the astra extraction.

## Basic Usage

### 1. Create Configuration

Write the site config in `astra.config.json`:

```json
{
  "ssg": {
    "docs": "docs",
    "output": "dist",
    "title": "My Site"
  }
}
```

### 2. Create Markdown Files

`docs/index.md`:

```markdown
---
title: Welcome
---

# Hello World

This is my documentation site.
```

### 3. Build

```bash
astra build
```

Generated files will be output to the `dist/` directory.
