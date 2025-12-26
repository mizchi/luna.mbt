---
title: Astra SSG
---

# Astra SSG

> **Experimental**: Astra is under active development. APIs may change.

Astra is Luna's static site generator for documentation and content sites.

## Features

- **Markdown-based** - Write content in Markdown with frontmatter
- **Syntax Highlighting** - Code blocks highlighted with Shiki
- **i18n Support** - Multi-language documentation
- **Auto Sidebar** - Automatic navigation generation from directory structure
- **Islands Architecture** - Embed interactive Luna/MoonBit components
- **Dynamic Routes** - Generate pages from `_slug_` patterns with staticParams
- **HMR** - Fast development with Hot Module Replacement

## Guides

- [Dynamic Routes](/astra/dynamic-routes/) - Generate static pages from parameters
- [Islands](/astra/islands/) - Embed interactive components in static pages

## Quick Start

### 1. Create a New Project

```bash
npx @luna_ui/astra new my-docs
cd my-docs
npm install
```

### 2. Start Development Server

```bash
npm run dev
```

Open http://localhost:3355 to preview your documentation with HMR.

### 3. Build for Production

```bash
npm run build
```

Static files are generated in `dist-docs/`.

## CLI Reference

```bash
# Create a new project
astra new <name> [options]
  -t, --title <text>  Site title (default: project name)
  -h, --help          Show help

# Start development server with HMR
astra dev [options]
  -p, --port <port>    Port to listen on (default: 3355)
  -c, --config <path>  Config file path
  -h, --help           Show help

# Build static site
astra build [options]
  -c, --config <path>  Config file path (default: astra.json)
  -o, --output <dir>   Output directory (overrides config)
  -h, --help           Show help

# Show help
astra --help

# Show version
astra --version
```

## Configuration

Create `astra.json` in your project root:

```json
{
  "docs": "docs",
  "output": "dist",
  "title": "My Docs",
  "base": "/",
  "sidebar": "auto"
}
```

### Basic Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `docs` | string | `"docs"` | Source directory |
| `output` | string | `"dist"` | Output directory |
| `title` | string | `"Documentation"` | Site title |
| `base` | string | `"/"` | Base URL path |
| `trailingSlash` | boolean | `true` | Use trailing slashes in URLs |
| `exclude` | string[] | `[]` | Directories to exclude |

### Navigation

```json
{
  "nav": [
    { "text": "Guide", "link": "/guide/" },
    { "text": "API", "link": "/api/" },
    { "text": "GitHub", "link": "https://github.com/..." }
  ]
}
```

### Sidebar

#### Auto Mode

```json
{
  "sidebar": "auto"
}
```

Generates sidebar from directory structure automatically.

#### Manual Mode

```json
{
  "sidebar": [
    {
      "text": "Introduction",
      "items": [
        { "text": "Getting Started", "link": "/getting-started/" },
        { "text": "Installation", "link": "/installation/" }
      ]
    },
    {
      "text": "Guide",
      "collapsed": true,
      "items": [
        { "text": "Basics", "link": "/guide/basics" },
        { "text": "Advanced", "link": "/guide/advanced" }
      ]
    }
  ]
}
```

### Internationalization (i18n)

```json
{
  "i18n": {
    "defaultLocale": "en",
    "locales": [
      { "code": "en", "label": "English", "path": "" },
      { "code": "ja", "label": "Japanese", "path": "ja" }
    ]
  }
}
```

Directory structure for i18n:

```
docs/
├── index.md           # English (default)
├── guide/
│   └── basics.md
└── ja/                # Japanese
    ├── index.md
    └── guide/
        └── basics.md
```

### Theme

```json
{
  "theme": {
    "primaryColor": "#6366f1",
    "logo": "/logo.svg",
    "footer": {
      "message": "Released under the MIT License.",
      "copyright": "Copyright 2024 Your Name"
    },
    "socialLinks": [
      { "icon": "github", "link": "https://github.com/..." }
    ]
  }
}
```

### OGP (Open Graph Protocol)

```json
{
  "ogp": {
    "siteUrl": "https://example.com",
    "image": "/og-image.png",
    "twitterHandle": "@yourhandle",
    "twitterCard": "summary_large_image"
  }
}
```

## Content Structure

```
docs/
├── index.md              # Home page (/)
├── 00_introduction/      # /introduction/
│   └── index.md
├── 01_guide/             # /guide/
│   ├── index.md
│   ├── 01_basics.md      # /guide/basics/
│   └── 02_advanced.md    # /guide/advanced/
└── components/           # Web Components
    └── my-counter.js
```

Numeric prefixes (`00_`, `01_`) control ordering but are stripped from URLs.

## Markdown Features

### Frontmatter

```markdown
---
title: Page Title
description: Page description for SEO
layout: doc
sidebar: true
---

# Content here
```

#### Frontmatter Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `title` | string | - | Page title |
| `description` | string | - | SEO description |
| `layout` | string | `"doc"` | Layout type: `doc`, `home` |
| `sidebar` | boolean | `true` | Show sidebar |
| `image` | string | - | OGP image (overrides site default) |

### Code Blocks

````markdown
```typescript
const greeting = "Hello, World!";
```

```moonbit
fn main {
  println("Hello, World!")
}
```
````

## Web Components

Embed interactive Web Components in your static pages.

### Creating a Component

Place components in `docs/components/`:

```javascript
// docs/components/my-counter.js
export function hydrate(element, state, name) {
  let count = parseInt(element.getAttribute('initial') || '0', 10);

  const render = () => {
    element.innerHTML = `<button>${count}</button>`;
    element.querySelector("button").onclick = () => {
      count++;
      render();
    };
  };

  render();
}
```

### Using in Markdown

```html
<my-counter initial="5" luna:trigger="load"></my-counter>
```

### Trigger Types

| Trigger | Description |
|---------|-------------|
| `load` | Hydrate immediately on page load (default) |
| `idle` | Hydrate when browser is idle |
| `visible` | Hydrate when element enters viewport |
| `media` | Hydrate when media query matches |
| `none` | Manual hydration only |

## Full Configuration Example

```json
{
  "docs": "docs",
  "output": "dist",
  "title": "My Documentation",
  "base": "/",
  "trailingSlash": true,
  "exclude": ["internal", "drafts"],
  "i18n": {
    "defaultLocale": "en",
    "locales": [
      { "code": "en", "label": "English", "path": "" },
      { "code": "ja", "label": "Japanese", "path": "ja" }
    ]
  },
  "nav": [
    { "text": "Guide", "link": "/guide/" },
    { "text": "API", "link": "/api/" }
  ],
  "sidebar": "auto",
  "theme": {
    "primaryColor": "#6366f1",
    "logo": "/logo.svg",
    "footer": {
      "message": "Released under the MIT License.",
      "copyright": "Copyright 2024"
    },
    "socialLinks": [
      { "icon": "github", "link": "https://github.com/..." }
    ]
  },
  "ogp": {
    "siteUrl": "https://example.com",
    "image": "/og-image.png"
  }
}
```
