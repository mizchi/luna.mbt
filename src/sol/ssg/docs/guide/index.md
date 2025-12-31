---
title: Getting Started
description: Overview and setup guide for Luna SSG
---

# Getting Started

Luna SSG is a static site generator integrated into the Sol CLI.

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
├── sol.config.json       # Configuration file
└── dist/                 # Output directory (auto-generated)
```

## Basic Usage

### 1. Create Configuration

Add an `ssg` section to `sol.config.json`:

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
sol ssg build
```

Generated files will be output to the `dist/` directory.
