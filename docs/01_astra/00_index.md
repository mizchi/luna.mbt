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
- **Auto Sidebar** - Automatic navigation generation
- **Islands Ready** - Embed interactive Luna components

## Quick Start

### 1. Create Configuration

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

### 2. Create Content

```
docs/
├── index.md           # Home page
├── getting-started/
│   └── index.md       # /getting-started/
└── guide/
    ├── basics.md      # /guide/basics
    └── advanced.md    # /guide/advanced
```

### 3. Build

```bash
astra build
```

Output is generated in `dist/`.

## Configuration

### Basic Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `docs` | string | `"docs"` | Source directory |
| `output` | string | `"dist"` | Output directory |
| `title` | string | `"Documentation"` | Site title |
| `base` | string | `"/"` | Base URL path |

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
      { "code": "ja", "label": "日本語", "path": "ja" }
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

### Exclude Directories

```json
{
  "exclude": ["internal", "drafts"]
}
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
    }
  }
}
```

## Web Components (Interactive Components)

Astra supports embedding interactive Web Components in your static pages using a convention-based approach.

### Convention

Place your Web Component files in `docs/components/`:

```
docs/
├── components/
│   ├── my-counter.js     # <my-counter> element
│   └── my-widget.js      # <my-widget> element
└── index.md
```

Component filenames must use kebab-case (contain a hyphen) to comply with Custom Elements naming requirements.

### Creating a Web Component

Create a JavaScript module with a `hydrate` function:

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

### Embedding in Markdown

Use the custom element tag directly in your markdown:

```html
<my-counter initial="5" luna:trigger="load"></my-counter>
```

#### Attributes

| Attribute | Description |
|-----------|-------------|
| `luna:trigger` | When to hydrate: `load`, `idle`, `visible`, `media`, `none` |
| (other attrs) | Passed as element attributes, accessible via `element.getAttribute()` |

### Live Demo

Try clicking the buttons:

<my-counter initial="0"></my-counter>

### Trigger Types

| Trigger | Description |
|---------|-------------|
| `load` | Hydrate immediately on page load (default) |
| `idle` | Hydrate when browser is idle (requestIdleCallback) |
| `visible` | Hydrate when element enters viewport (IntersectionObserver) |
| `media` | Hydrate when media query matches |
| `none` | Manual hydration only |

### How It Works

When Astra processes markdown, custom element tags are converted to HTML with hydration attributes:

```html
<my-counter initial="0" luna:wc-url="/components/my-counter.js" luna:wc-trigger="load"></my-counter>
```

The built-in wc-loader script automatically hydrates components when their trigger conditions are met.

## Markdown Features

### Frontmatter

```markdown
---
title: Page Title
description: Page description for SEO
---

# Content here
```

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

### Tables

```markdown
| Feature | Status |
|---------|--------|
| Markdown | ✅ |
| Syntax Highlighting | ✅ |
```

## CLI Reference

```bash
# Build static site
astra build

# Build with custom output
astra build -o public

# Build with custom config
astra build -c custom.json

# Show help
astra --help
```

## Full Configuration Example

```json
{
  "docs": "docs",
  "output": "dist",
  "title": "Luna Documentation",
  "base": "/",
  "exclude": ["internal"],
  "i18n": {
    "defaultLocale": "en",
    "locales": [
      { "code": "en", "label": "English", "path": "" },
      { "code": "ja", "label": "日本語", "path": "ja" }
    ]
  },
  "nav": [
    { "text": "Guide", "link": "/guide/" },
    { "text": "Tutorial", "link": "/tutorial/" },
    { "text": "API", "link": "/api/" }
  ],
  "sidebar": "auto",
  "theme": {
    "primaryColor": "#6366f1",
    "footer": {
      "message": "Released under the MIT License.",
      "copyright": "Copyright 2024"
    }
  }
}
```
