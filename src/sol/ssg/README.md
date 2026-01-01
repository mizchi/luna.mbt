# Sol SSG

Static Site Generator (SSG). Markdown → HTML conversion.

## Overview

An SSG specialized for documentation site generation.
Generates multi-language static sites from Markdown files.

## Module Structure

| Submodule | Responsibility |
|-----------|----------------|
| `assets/` | Asset loading (CSS, JS) |
| `cache/` | Disk cache, hash utilities |
| `components/` | Reusable UI components (Header, Footer, TOC, Blog) |
| `generator/` | HTML generation logic |
| `mdx/` | MDX parsing |
| `themes/` | Theme system |
| `tree/` | Document tree building |
| `types.mbt` | Core type definitions |

## Related Modules

| Module | Responsibility |
|--------|----------------|
| `sol/cli/` | CLI entry point |
| `sol/routes/` | Route generation, file-based routing |
| `sol/parser/` | MoonBit source parsing |
| `sol/isr/` | ISR (Incremental Static Regeneration) |
| `sol/content/` | Markdown, frontmatter, Shiki integration |

## Config File (sol.config.json)

```json
{
  "docs": "docs",
  "output": "dist",
  "title": "My Site",
  "base": "/",
  "trailingSlash": true,
  "i18n": {
    "defaultLocale": "en",
    "locales": [
      { "code": "en", "label": "English", "path": "" },
      { "code": "ja", "label": "日本語", "path": "ja" }
    ]
  },
  "nav": [...],
  "sidebar": "auto"
}
```

## Main Types

### SsgConfig

```moonbit
pub struct SsgConfig {
  docs_dir : String       // Source directory
  output_dir : String     // Output directory
  title : String          // Site title
  base_url : String       // Base URL
  nav : Array[NavItem]    // Navigation
  sidebar : SidebarConfig // Sidebar config
  i18n : I18nConfig       // Multi-language config
  // ...
}
```

## Features

- Static HTML generation from Markdown
- Multi-language support (i18n)
- Auto sidebar generation
- Syntax highlighting (Shiki)
- OGP support
- Disk cache for incremental builds
- Component customization

## Usage

```bash
# Run from CLI
moon run src/sol/cli -- build
```

## References

- [Luna Core](../../luna/README.md) - VNode generation
- [Sol](../README.md) - SSR framework
