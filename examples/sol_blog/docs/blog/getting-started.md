---
title: Getting Started with Astra
description: A beginner's guide to using Astra SSG
date: "2024-12-27"
author: Luna Team
tags:
  - tutorial
  - beginner
  - astra
layout: blog-post
featured: true
---

# Getting Started with Astra

Astra is a static site generator built with MoonBit.

## Installation

First, install the Luna CLI:

```bash
npx @luna_ui/luna new mysite
cd mysite
```

## Configuration

Create a `sol.config.json` file:

```json
{
  "title": "My Site",
  "docs_dir": "docs",
  "out_dir": "dist"
}
```

## Writing Content

Create markdown files in the `docs/` directory:

```markdown
---
title: My First Post
date: "2024-12-27"
author: Your Name
tags:
  - hello
---

# Hello World

This is my first post!
```

## Building

Run the build command:

```bash
npx astra build
```

Your static site will be generated in the `dist/` directory.

## Next Steps

- Learn about [layouts and themes](#)
- Explore [advanced configuration](#)
- Deploy to [Cloudflare Pages](#)
